#!/bin/bash
# CAFE345 VM 테스트 환경 구축 스크립트
# 작성일: 2025-09-09

echo "=== CAFE345 VM 환경 구축 시작 ==="
echo "현재 시간: $(date)"
echo "현재 사용자: $(whoami)"
echo "시스템 정보: $(uname -a)"
echo

# Phase 1: 기본 환경 확인
echo "=== Phase 1: 기본 환경 확인 ==="
echo "1.1 SSH 서비스 상태 확인"
systemctl status sshd --no-pager
echo

echo "1.2 네트워크 설정 확인"
ip addr show | grep inet
echo

echo "1.3 방화벽 상태 확인"
firewall-cmd --list-all
echo

# Phase 2: LAMP 스택 설치
echo "=== Phase 2: LAMP 스택 설치 ==="
echo "2.1 패키지 업데이트"
dnf update -y

echo "2.2 LAMP 스택 설치"
dnf install -y httpd php php-mysqlnd mariadb-server php-gd php-curl php-zip php-xml php-mbstring

echo "2.3 서비스 시작 및 활성화"
systemctl enable --now httpd mariadb

echo "2.4 방화벽 설정"
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

echo "2.5 서비스 상태 확인"
systemctl status httpd --no-pager
systemctl status mariadb --no-pager
echo

# Phase 3: SSH 설정 개선
echo "=== Phase 3: SSH 설정 개선 ==="
echo "3.1 SSH 설정 백업"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)

echo "3.2 SSH 설정 수정"
# SSH 설정 개선
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

echo "3.3 SSH 서비스 재시작"
systemctl restart sshd

echo "3.4 SSH 키 디렉토리 확인"
mkdir -p /root/.ssh
chmod 700 /root/.ssh
mkdir -p /home/cafe345/.ssh
chmod 700 /home/cafe345/.ssh
chown cafe345:cafe345 /home/cafe345/.ssh

echo

# Phase 4: 웹 환경 준비
echo "=== Phase 4: 웹 환경 준비 ==="
echo "4.1 웹 디렉토리 권한 설정"
chown -R apache:apache /var/www/html/
chmod 755 /var/www/html/

echo "4.2 PHP 테스트 파일 생성"
cat > /var/www/html/phpinfo.php << 'EOF'
<?php
phpinfo();
?>
EOF

echo "4.3 웹서버 접근 테스트"
curl -I http://localhost/ 2>/dev/null | head -1
curl -s http://localhost/phpinfo.php | grep -i "php version" | head -1

echo

# Phase 5: 데이터베이스 설정
echo "=== Phase 5: 데이터베이스 설정 ==="
echo "5.1 MariaDB 보안 설정 준비"
# 자동화된 보안 설정
mysql -e "UPDATE mysql.user SET Password=PASSWORD('cafe345!@#') WHERE User='root';"
mysql -e "DELETE FROM mysql.user WHERE User='';"
mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
mysql -e "DROP DATABASE IF EXISTS test;"
mysql -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';"
mysql -e "FLUSH PRIVILEGES;"

echo "5.2 테스트 데이터베이스 생성"
mysql -u root -pcafe345!@# -e "CREATE DATABASE IF NOT EXISTS cafe345_test CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

echo

# Phase 6: 시스템 정보 요약
echo "=== Phase 6: 설치 완료 정보 ==="
echo "6.1 설치된 패키지 버전"
echo "Apache: $(httpd -v | head -1)"
echo "PHP: $(php -v | head -1)"
echo "MariaDB: $(mysql --version)"
echo

echo "6.2 서비스 상태"
systemctl is-active httpd mariadb sshd

echo "6.3 네트워크 포트 확인"
ss -tlnp | grep -E ":(22|80|3306)"

echo

echo "6.4 웹 접근 정보"
echo "웹사이트: http://$(hostname -I | awk '{print $1}')/"
echo "PHP Info: http://$(hostname -I | awk '{print $1}')/phpinfo.php"
echo

echo "=== CAFE345 VM 환경 구축 완료 ==="
echo "완료 시간: $(date)"
echo "다음 단계: 웹소스 업로드 및 복원"
echo