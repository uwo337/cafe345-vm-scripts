#!/bin/bash
# CAFE345 웹소스 복원 스크립트
# 백업 파일: d:\CAFE345\public_html_core_0909.tar.gz (3.5G)

echo "=== CAFE345 웹소스 복원 시작 ==="
echo "현재 시간: $(date)"
echo "현재 사용자: $(whoami)"

# 변수 설정
BACKUP_FILE="/home/cafe345/public_html_core_0909.tar.gz"
WEB_DIR="/var/www/html"
BACKUP_DIR="/home/cafe345/web_backup_$(date +%Y%m%d_%H%M%S)"

# Phase 1: 백업 파일 확인
echo "=== Phase 1: 백업 파일 확인 ==="
if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: 백업 파일을 찾을 수 없습니다: $BACKUP_FILE"
    echo "파일을 먼저 업로드해주세요."
    exit 1
fi

echo "백업 파일 정보:"
ls -lh "$BACKUP_FILE"
echo

# Phase 2: 기존 웹 디렉토리 백업
echo "=== Phase 2: 기존 웹 디렉토리 백업 ==="
if [ -d "$WEB_DIR" ] && [ "$(ls -A $WEB_DIR)" ]; then
    echo "기존 웹 디렉토리를 백업합니다..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$WEB_DIR"/* "$BACKUP_DIR"/ 2>/dev/null
    echo "백업 완료: $BACKUP_DIR"
fi

# Phase 3: 웹 디렉토리 정리
echo "=== Phase 3: 웹 디렉토리 정리 ==="
rm -rf "$WEB_DIR"/*
echo "웹 디렉토리 정리 완료"

# Phase 4: 백업 파일 압축 해제
echo "=== Phase 4: 백업 파일 압축 해제 ==="
echo "압축 파일 내용 미리보기:"
tar -tzf "$BACKUP_FILE" | head -10

echo "압축 해제 중... (시간이 소요될 수 있습니다)"
cd /home/cafe345/
tar -xzf "$BACKUP_FILE"

# 압축 해제된 디렉토리 확인
EXTRACTED_DIR=$(tar -tzf "$BACKUP_FILE" | head -1 | cut -d'/' -f1)
echo "압축 해제된 디렉토리: $EXTRACTED_DIR"

if [ ! -d "$EXTRACTED_DIR" ]; then
    echo "ERROR: 압축 해제 실패"
    exit 1
fi

# Phase 5: 웹소스 복사
echo "=== Phase 5: 웹소스 복사 ==="
cp -r "$EXTRACTED_DIR"/* "$WEB_DIR"/
echo "웹소스 복사 완료"

# Phase 6: 권한 설정
echo "=== Phase 6: 권한 설정 ==="
chown -R apache:apache "$WEB_DIR"
chmod 755 "$WEB_DIR"
find "$WEB_DIR" -type f -exec chmod 644 {} \;
find "$WEB_DIR" -type d -exec chmod 755 {} \;

# 특별한 권한이 필요한 디렉토리들
if [ -d "$WEB_DIR/assets/libraries/uploads" ]; then
    chmod -R 777 "$WEB_DIR/assets/libraries/uploads"
fi
if [ -d "$WEB_DIR/upload" ]; then
    chmod -R 777 "$WEB_DIR/upload"
fi

echo "권한 설정 완료"

# Phase 7: 핵심 파일 구조 검증
echo "=== Phase 7: 핵심 파일 구조 검증 ==="
echo "핵심 파일 존재 확인:"
[ -f "$WEB_DIR/index.php" ] && echo "✓ index.php" || echo "✗ index.php"
[ -f "$WEB_DIR/config.php" ] && echo "✓ config.php" || echo "✗ config.php"
[ -f "$WEB_DIR/assets/init.php" ] && echo "✓ assets/init.php" || echo "✗ assets/init.php"
[ -d "$WEB_DIR/assets/includes" ] && echo "✓ assets/includes/" || echo "✗ assets/includes/"

echo "includes 디렉토리 파일 개수:"
if [ -d "$WEB_DIR/assets/includes" ]; then
    find "$WEB_DIR/assets/includes" -name "*.php" | wc -l
fi

# Phase 8: config.php 확인 및 수정 준비
echo "=== Phase 8: config.php 확인 ==="
if [ -f "$WEB_DIR/config.php" ]; then
    echo "현재 데이터베이스 설정:"
    grep -E "(sql_db_host|sql_db_name|sql_db_user)" "$WEB_DIR/config.php" | head -3
    
    # config.php 백업
    cp "$WEB_DIR/config.php" "$WEB_DIR/config.php.backup.$(date +%Y%m%d_%H%M%S)"
    echo "config.php 백업 완료"
fi

# Phase 9: 웹서버 테스트
echo "=== Phase 9: 웹서버 테스트 ==="
echo "Apache 상태: $(systemctl is-active httpd)"
echo "웹사이트 접근 테스트:"
curl -I http://localhost/ 2>/dev/null | head -1

# Phase 10: 결과 요약
echo "=== Phase 10: 복원 완료 요약 ==="
echo "복원 완료 시간: $(date)"
echo "웹 디렉토리: $WEB_DIR"
echo "웹 디렉토리 크기: $(du -sh $WEB_DIR)"
echo "웹 파일 개수: $(find $WEB_DIR -type f | wc -l)"
echo
echo "다음 단계:"
echo "1. 데이터베이스 복원"
echo "2. config.php 설정 수정"
echo "3. 웹사이트 접근 테스트"
echo "4. 로그인 기능 테스트"
echo
echo "웹사이트 URL: http://$(hostname -I | awk '{print $1}')/"