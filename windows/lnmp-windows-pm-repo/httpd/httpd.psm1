Import-Module downloader
Import-Module unzip
Import-Module command
Import-Module cleanup
Import-Module ln
Import-Module sudo

$HTTPD_MOD_FCGID_VERSION="2.3.10"

$lwpm=ConvertFrom-Json -InputObject (get-content $PSScriptRoot/lwpm.json -Raw)

$stable_version=$lwpm.version
$pre_version=$lwpm.'pre-version'
$github_repo=$lwpm.github
$homepage=$lwpm.homepage
$releases=$lwpm.releases
$bug=$lwpm.bug
$name=$lwpm.name
$description=$lwpm.description
$url=$lwpm.url
$url_mirror=$lwpm.'url-mirror'
$pre_url=$lwpm.'pre-url'
$pre_url_mirror=$lwpm.'pre-url-mirror'

Function _after_install(){
  $a=Select-String 'IncludeOptional conf.d/' C:\Apache24\conf\httpd.conf

  if ($a.Length -eq 0){
    "==> Add config in C:\Apache24\conf\httpd.conf"

    echo ' ' | out-file -Append C:\Apache24\conf\httpd.conf
    "IncludeOptional conf.d/*.conf
LoadModule ssl_module modules/mod_ssl.so
LoadModule headers_module modules/mod_headers.so
LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
" | out-file -Append C:\Apache24\conf\httpd.conf
  }
}

Function _install($VERSION=0,$isPre=0){
  if(!($VERSION)){
    $VERSION=$stable_version
  }

  if($isPre){
    $VERSION=$pre_version
  }

  $url=$url.replace('${VERSION}',${VERSION});

  $filename="httpd-${VERSION}-win64-VS16.zip"
  $unzipDesc="httpd"

  _exportPath "C:\Apache24\bin"

  if($(_command httpd)){
    $CURRENT_VERSION=($(httpd -v) -split " ")[2].trim("Apache/")

    if ($CURRENT_VERSION -eq $VERSION){
        "==> $name $VERSION already install"
        return
    }
  }

  # 下载原始 zip 文件，若存在则不再进行下载

  _downloader `
    $url `
    $filename `
    $name `
    $VERSION

  _downloader `
    "https://www.apachelounge.com/download/VS16/modules/mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16.zip" `
    "mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16.zip" `
    "httpd_mod_fcgid" `
    ${HTTPD_MOD_FCGID_VERSION}

  # 验证原始 zip 文件 Fix me

  # 解压 zip 文件 Fix me
  _cleanup $unzipDesc
  _unzip $filename $unzipDesc
  # 安装 Fix me
  _mkdir C:\Apache24
  Copy-item -r -force "httpd\Apache24" "C:\"
  if (!(Test-Path C:\Apache24\modules\mod_fcgid.so)){
    _unzip mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16.zip `
           mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16

    copy-item mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16\mod_fcgid-${HTTPD_MOD_FCGID_VERSION}\mod_fcgid.so `
              C:\Apache24\modules

    _cleanup mod_fcgid-${HTTPD_MOD_FCGID_VERSION}-win64-VS16
  }

  # Start-Process -FilePath $filename -wait
  # _cleanup ""

  # [environment]::SetEnvironmentvariable("", "", "User")
  $HTTPD_IS_RUN=0

  get-service Apache2.4 > $null 2>&1

  if (!($?)){
      _sudo "httpd -k install"
      $HTTPD_IS_RUN=1
  }

  _sudo set-service Apache2.4 -StartupType Manual

  mkdir C:\Apache24\conf.d | out-null

  _ln C:\Apache24\conf.d $env:USERPROFILE\lnmp\windows\httpd

  _ln C:\Apache24\logs $env:USERPROFILE\lnmp\windows\logs\httpd

  _cleanup $unzipDesc

  _after_install

  _exportPath "C:\Apache24\bin"

  "==> Checking ${name} ${VERSION} install ..."
  # 验证 Fix me
  httpd -v
}

Function _uninstall(){
  _sudo "httpd -k uninstall"
  _cleanup C:\Apache24
}
