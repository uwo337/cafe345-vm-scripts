# CAFE345 VM 테스트 환경 구축 스크립트

CAFE345 웹사이트 테스트 환경을 VM에 구축하기 위한 자동화 스크립트 모음입니다.

## 스크립트 목록

### 1. vm_setup_script.sh
- VM 기본 환경 구축 (LAMP 스택 설치)
- SSH 설정 개선
- 방화벽 및 보안 설정
- 서비스 활성화 및 상태 확인

### 2. ssh_setup_script.sh
- SSH 접속 문제 해결
- 키 기반 인증 설정
- SSH 서비스 최적화
- 네트워크 접근 권한 설정

### 3. web_restore_script.sh
- 웹소스 백업 파일 복원
- 권한 및 소유자 설정
- 핵심 파일 구조 검증
- 웹서버 연동 테스트

## 사용 방법

### VM에서 스크립트 다운로드 및 실행

1. **VM에 접속** (PuTTY 등 사용)
```bash
ssh root@192.168.239.129
# 또는
ssh cafe345@192.168.239.129
```

2. **스크립트 다운로드**
```bash
# 작업 디렉토리 생성
mkdir -p /home/cafe345/scripts
cd /home/cafe345/scripts

# 스크립트 다운로드
curl -O https://raw.githubusercontent.com/uwo337/cafe345-vm-scripts/main/vm_setup_script.sh
curl -O https://raw.githubusercontent.com/uwo337/cafe345-vm-scripts/main/ssh_setup_script.sh
curl -O https://raw.githubusercontent.com/uwo337/cafe345-vm-scripts/main/web_restore_script.sh

# 실행 권한 부여
chmod +x *.sh
```

3. **순서대로 실행**
```bash
# 1단계: VM 기본 환경 구축 (root 권한 필요)
sudo ./vm_setup_script.sh

# 2단계: SSH 설정 개선 (root 권한 필요)
sudo ./ssh_setup_script.sh

# 3단계: 웹소스 복원 (백업 파일 업로드 후)
sudo ./web_restore_script.sh
```

## 전제 조건

### VM 환경
- OS: AlmaLinux 9.6
- RAM: 최소 4GB
- 디스크: 200GB 여유 공간
- 네트워크: NAT 또는 Bridged 설정

### 백업 파일
- 웹소스: public_html_core_0909.tar.gz (3.5GB)
- 위치: /home/cafe345/ 디렉토리에 업로드 필요

### 계정 정보
- root 비밀번호: cafe345!@#
- cafe345 비밀번호: cafe345!@#

## 실행 결과

### 성공 시 확인 사항
- Apache, MariaDB, SSH 서비스 정상 작동
- 웹사이트 접근 가능: http://VM_IP/
- SSH 원격 접속 가능
- 핵심 웹 파일들 정상 복원

### 문제 해결
스크립트 실행 중 오류 발생 시:

1. **로그 확인**
```bash
# Apache 로그
sudo tail -50 /var/log/httpd/error_log

# SSH 로그
sudo journalctl -u sshd -n 20

# 시스템 로그
sudo dmesg | tail -20
```

2. **서비스 상태 확인**
```bash
sudo systemctl status httpd mariadb sshd
```

3. **네트워크 확인**
```bash
ip addr show
ss -tlnp | grep -E ":(22|80|3306)"
```

## 주의사항

- 스크립트는 root 권한으로 실행해야 합니다
- 기존 설정이 변경될 수 있으니 중요한 데이터는 미리 백업하세요
- 네트워크 연결이 안정적인 환경에서 실행하세요
- 웹소스 복원 전에 반드시 백업 파일을 업로드하세요

## 다음 단계

스크립트 실행 완료 후:
1. 데이터베이스 복원
2. config.php 설정 수정
3. 웹사이트 기능 테스트
4. 로그인 및 그룹 접근 테스트

---

**작성일:** 2025-09-09  
**작성자:** CAFE345 개발팀  
**목적:** 테스트 환경 신속한 구축