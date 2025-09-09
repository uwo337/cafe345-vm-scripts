#!/bin/bash
# SSH 키 기반 인증 설정 스크립트
# VM에서 실행할 스크립트

echo "=== SSH 키 기반 인증 설정 시작 ==="
echo "현재 시간: $(date)"

# 1. SSH 서비스 확인
echo "1. SSH 서비스 상태 확인"
systemctl status sshd --no-pager -l

# 2. SSH 설정 파일 확인
echo "2. 현재 SSH 설정 확인"
echo "PasswordAuthentication: $(grep -E '^#?PasswordAuthentication' /etc/ssh/sshd_config)"
echo "PubkeyAuthentication: $(grep -E '^#?PubkeyAuthentication' /etc/ssh/sshd_config)"
echo "PermitRootLogin: $(grep -E '^#?PermitRootLogin' /etc/ssh/sshd_config)"

# 3. SSH 설정 개선
echo "3. SSH 설정 개선"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)

# SSH 설정 수정
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' /etc/ssh/sshd_config

# 4. SSH 키 디렉토리 생성
echo "4. SSH 키 디렉토리 생성"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

mkdir -p /home/cafe345/.ssh
chmod 700 /home/cafe345/.ssh
touch /home/cafe345/.ssh/authorized_keys
chmod 600 /home/cafe345/.ssh/authorized_keys
chown -R cafe345:cafe345 /home/cafe345/.ssh

# 5. SSH 호스트 키 재생성 (필요시)
echo "5. SSH 호스트 키 확인"
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "SSH 호스트 키 재생성..."
    ssh-keygen -A
fi

# 6. SELinux 컨텍스트 설정 (SELinux가 활성화된 경우)
if command -v getenforce >/dev/null 2>&1 && [ "$(getenforce)" != "Disabled" ]; then
    echo "6. SELinux 컨텍스트 설정"
    restorecon -R /root/.ssh
    restorecon -R /home/cafe345/.ssh
fi

# 7. SSH 서비스 재시작
echo "7. SSH 서비스 재시작"
systemctl restart sshd

# 8. 방화벽 SSH 포트 확인
echo "8. 방화벽 SSH 포트 확인"
firewall-cmd --list-services | grep -q ssh || firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# 9. 최종 상태 확인
echo "9. 최종 상태 확인"
echo "SSH 서비스: $(systemctl is-active sshd)"
echo "SSH 포트: $(ss -tlnp | grep :22)"
echo "네트워크 인터페이스:"
ip addr show | grep -E "(inet |UP,)"

# 10. 테스트용 임시 키 생성 (옵션)
echo "10. 테스트용 SSH 키 생성"
if [ ! -f /root/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
    echo "생성된 공개키:"
    cat /root/.ssh/id_rsa.pub
fi

echo "=== SSH 설정 완료 ==="
echo "완료 시간: $(date)"
echo
echo "다음 단계:"
echo "1. 클라이언트에서 SSH 키를 생성하고"
echo "2. 공개키를 authorized_keys에 추가하거나"
echo "3. 비밀번호 인증으로 테스트 접속"