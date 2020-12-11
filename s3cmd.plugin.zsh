# zsh plugin for s3cmd

# github: https://github.com/FFKL/s3cmd-zsh-plugin.git

# Copyright (C) 2020 Dmitrii Korostelev

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

function _command() {
  integer ret=1
  local -a _commands
  _commands=(
    'mb:Make bucket'
    'rb:Remove bucket'
    'ls:List objects or buckets'
    'la:List all object in all buckets'
    'put:Put file into bucket'
    'get:Get file from bucket'
    'del:Delete file from bucket'
    'rm:Delete file from bucket'
    'restore:Restore file from Glacier storage'
    'sync:Synchronize a directory tree to S3'
    'du:Disk usage by buckets'
    'info:Get various information about Buckets or Files'
    'cp:Copy object'
    'modify:Modify object metadata'
    'mv:Move object'
    'setacl:Modify Access control list for Bucket or Files'
    'setpolicy:Modify Bucket Policy'
    'delpolicy:Delete Bucket Policy'
    'setcors:Modify Bucket CORS'
    'delcors:Delete Bucket CORS'
    'payer:Modify Bucket Requester Pays policy'
    'multipart:Show multipart uploads'
    'abortmp:Abort a multipart upload'
    'listmp:List parts of a multipart upload'
    'accesslog:Enable/disable bucket access logging'
    'sign:Sign arbitrary string using the secret key'
    'signurl:Sign an S3 URL to provide limited public access with expiry'
    'fixbucket:Fix invalid file names in a bucket'
    'ws-create:Create Website from bucket'
    'ws-delete:Delete Website'
    'ws-info:Info about Website'
    'expire:Set or delete expiration rule for the bucket'
    'setlifecycle:Upload a lifecycle policy for the bucket'
    'getlifecycle:Get a lifecycle policy for the bucket'
    'dellifecycle:Remove a lifecycle policy for the bucket'
    'cflist:List CloudFront distribution points'
    'cfinfo:Display CloudFront distribution point parameters'
    'cfcreate:Create CloudFront distribution point'
    'cfdelete:Delete CloudFront distribution point'
    'cfmodify:Change CloudFront distribution point parameters'
    'cfinvalinfo:Display CloudFront invalidation request(s) status'
  )
  _describe -t commands 'command' _commands && ret=0

  return ret
}

function _cut_prefix() {
  local _prefix=$1
  local _line _result
  while IFS=$'\n' read -r _line; do
    _result="${_result}${_line#$_prefix}\n"
  done
  echo $_result

  return 0
}

function _bucket() {
  integer ret=1
  local _path _temp_IFS _prefix
  local -a _buckets _s3_files _s3_dirs _search_result
  local _search_term=$(echo "${words[-1]}" | grep -o '^s3://\S*/.*' | sed 's/\\ / /g')
  if [[ -z "$_search_term" ]]; then
    _buckets=($(s3cmd ls | grep -o 's3://.*$' | _cut_prefix "$_search_term" | sed 's/:/\\:\\/g'))
    _describe -t buckets 'buckets' _buckets -P "$_search_term" -S '/' && ret=0
  else
    _search_result=$(s3cmd ls "$_search_term")
    _temp_IFS=$IFS
    IFS=$'\n'
    _s3_files=($(echo "$_search_result" | grep --invert-match '^\s*DIR\s*s3://.*$' | grep -o 's3://.*$' | _cut_prefix "$_search_term" | sed 's/:/\\:\\/g'))
    _s3_dirs=($(echo "$_search_result" | grep '^\s*DIR\s*s3://.*$' | grep -o 's3://.*$' | _cut_prefix "$_search_term" | sed 's/:/\\:\\/g'))
    _prefix=$(echo "$_search_term" | sed 's/ /\\ /g')
    ((${#_s3_files[@]})) && _describe -t files 'files' _s3_files -P "$_prefix" && ret=0
    ((${#_s3_dirs[@]})) && _describe -t directories 'directories' _s3_dirs -P "$_prefix" -S '' && ret=0
    IFS=$_temp_IFS
  fi

  return ret
}

function _cf_point() {
  compadd -S '' 'cf://'

  return 0
}

function _command_argument() {
  integer ret=1
  case "$words[1]" in
  mb | rb | du | info | modify | setacl | delpolicy | delcors | payer | multipart | abortmp | \
    listmp | accesslog | signurl | fixbucket | ws-create | ws-delete | ws-info | expire | getlifecycle | dellifecycle | cfcreate)
    _arguments "1:bucket:_bucket" && ret=0
    ;;
  sign | cflist)
    ret=0
    ;;
  ls)
    _arguments "--limit=[Limit number of objects returned in the response body]:limit: " \
      "--list-md5[Include MD5 sums in bucket listings]" \
      "(-l --long-listing)"{-l,--long-listing}"[Produce long listing]" \
      "1:bucket:_bucket" && ret=0
    ;;
  la)
    _arguments "--limit=[Limit number of objects returned in the response body]:limit: " && ret=0
    ;;
  put)
    _arguments "(--rr --reduced-redundancy)"{--rr,--reduced-redundancy}"[Store object with 'Reduced redundancy'. Lower per-GB price]" \
      "(--no-rr --no-reduced-redundancy)"{--no-rr,--no-reduced-redundancy}"[Store object without 'Reduced redundancy'. Higher per-GB price]" \
      "--storage-class=[Store object with specified CLASS. Lower per-GB price]:class:(STANDARD STANDARD_IA REDUCED_REDUNDANCY)" \
      "--server-side-encryption[Specifies that server-side encryption will be used when putting objects]" \
      "--server-side-encryption-kms-id=[Specifies the key id used for server-side encryption with AWS KMS-Managed Keys (SSE-KMS) when putting objects]:kms key: " \
      "(-r --recursive)"{-r,--recursive}"[Recursive upload]" \
      "1:filepath:_files" \
      "2:bucket:_bucket" && ret=0
    ;;
  setpolicy | setcors | setlifecycle)
    _arguments "1:filepath:_files" "2:bucket:_bucket" && ret=0
    ;;
  get)
    _arguments "--continue[Continue getting a partially downloaded file]" \
      "--skip-existing[Skip over files that exist at the destination]" \
      "--delete-after-fetch[Delete remote objects after fetching to local file]" \
      "(-r --recursive)"{-r,--recursive}"[Recursive upload, download or removal]" \
      "1:bucket:_bucket" \
      "2:file:_files" && ret=0
    ;;
  del | rm | restore)
    _arguments "1:bucket:_bucket" && ret=0
    ;;
  sync)
    _arguments "--skip-existing[Skip over files that exist at the destination]" \
      "--check-md5[Check MD5 sums when comparing (default)]" \
      "--no-check-md5[Do not check MD5 sums when comparing files]" \
      "--delete-removed[Delete destination objects with no corresponding source file]" \
      "--delete-after[Perform deletes after new uploads]" \
      "--delay-updates[!OBSOLETE! Put all updated files into place at end]" \
      "--max-delete=[Do not delete more than NUM files]:files count: " \
      "--delete-after-fetch[Delete remote objects after fetching to local file]" \
      "(-p --preserve)"{-p,--preserve}"[Preserve filesystem attributes (mode, ownership, timestamps) (default)]" \
      "--server-side-encryption[Specifies that server-side encryption will be used when putting objects]" \
      "--server-side-encryption-kms-id=[Specifies the key id used for server-side encryption with AWS KMS-Managed Keys (SSE-KMS) when putting objects]:kms key: " \
      "1:dir:_files" \
      "2:bucket:_bucket" && ret=0
    ;;
  cp)
    _arguments "(--rr --reduced-redundancy)"{--rr,--reduced-redundancy}"[Store object with 'Reduced redundancy'. Lower per-GB price]" \
      "(--no-rr --no-reduced-redundancy)"{--no-rr,--no-reduced-redundancy}"[Store object without 'Reduced redundancy'. Higher per-GB price]" \
      "--storage-class=[Store object with specified CLASS. Lower per-GB price]:class:(STANDARD STANDARD_IA REDUCED_REDUNDANCY)" \
      "--server-side-encryption[Specifies that server-side encryption will be used when putting objects]" \
      "--server-side-encryption-kms-id=[Specifies the key id used for server-side encryption with AWS KMS-Managed Keys (SSE-KMS) when putting objects]:kms key: " \
      "1:bucket:_bucket" \
      "2:bucket:_bucket" && ret=0
    ;;
  mv)
    _arguments "(--rr --reduced-redundancy)"{--rr,--reduced-redundancy}"[Store object with 'Reduced redundancy'. Lower per-GB price]" \
      "(--no-rr --no-reduced-redundancy)"{--no-rr,--no-reduced-redundancy}"[Store object without 'Reduced redundancy'. Higher per-GB price]" \
      "--storage-class=[Store object with specified CLASS. Lower per-GB price]:class:(STANDARD STANDARD_IA REDUCED_REDUNDANCY)" \
      "1:bucket:_bucket" \
      "2:bucket:_bucket" && ret=0
    ;;
  cfinfo | cfdelete | cfinvalinfo)
    _arguments "1:cf:_cf_point" && ret=0
    ;;
  cfmodify)
    _arguments "--access-logging-target-prefix=[Target prefix for access logs (S3 URI)]:prefix: " \
      "--no-access-logging[Disable access logging]" \
      "--enable[Enable given CloudFront distribution]" \
      "--disable[Disable given CloudFront distribution]" \
      "--cf-add-cname=[Add given CNAME to a CloudFront distribution]:cname: " \
      "--cf-remove-cname=[Remove given CNAME from a CloudFront distribution]:cname: " \
      "--cf-comment=[Set COMMENT for a given CloudFront distribution]:comment: " \
      "--cf-default-root-object=[Set the default root object to return when no object is specified in the URL. Use a relative path]:path: " \
      "1:cf:_cf_point" && ret=0
    ;;
  esac

  return ret
}

function _s3cmd() {
  integer ret=1
  local curcontext="$curcontext" state help="-h --help"
  local -a _options
  _options=(
    "(: -)"{-h,--help}"[Show help message and exit]"
    "($help)--configure[Invoke interactive (re)configuration tool]"
    "($help -c --config)"{-c,--config}"=[Config file name. Defaults to \$HOME/.s3cfg]:config: "
    "(: -)--dump-config[Dump current configuration after parsing config files and command line options and exit]"
    "($help)--access_key=[AWS Access Key]:access key: "
    "($help)--secret_key=[AWS Secret Key]:secret key: "
    "($help)--access_token=[AWS Access Token]:token: "
    "($help -n --dry-run)"{-n,--dry-run}"[Only show what should be uploaded or downloaded but don't actually do it]"
    "($help -s --ssl)"{-s,--ssl}"[Use HTTPS connection when communicating with S3 (default)]"
    "($help)--no-ssl[Don't use HTTPS]"
    "($help -e --encrypt)"{-e,--encrypt}"[Encrypt files before uploading to S3]"
    "($help)--no-encrypt[Don't encrypt files]"
    "($help -f --force)"{-f,--force}"[Force overwrite and other dangerous operations]"
    "($help)--continue[Continue getting a partially downloaded file (only for 'get' command)]"
    "($help)--continue-put[Continue uploading partially uploaded files or multipart upload parts]"
    "($help)--upload-id=[UploadId for Multipart Upload, in case you want to continue an existing upload]:upload id: "
    "($help)--skip-existing[Skip over files that exist at the destination (only for 'get' and 'sync' commands)]"
    "($help -r --recursive)"{-r,--recursive}"[Recursive upload, download or removal]"
    "($help)--check-md5[Check MD5 sums when comparing files for 'sync' (default)]"
    "($help)--no-check-md5[Do not check MD5 sums when comparing files for 'sync']"
    "($help -P --acl-public)"{-P,--acl-public}"[Store objects with ACL allowing read for anyone]"
    "($help)--acl-private[Store objects with default ACL allowing access for you only]"
    "($help)--acl-grant=[Grant stated permission to a given amazon user]:permissions:(read write read_acp write_acp full_control all)"
    "($help)--acl-revoke=[Revoke stated permission for a given amazon user]:permissions:(read write read_acp write_acp full_control all)"
    "($help -D --restore-days)"{-D,--restore-days}"=[Number of days to keep restored file available (only for 'restore' command)]:restore days: "
    "($help)--restore-priority[Priority for restoring files from S3 Glacier (only for 'restore' command)]:restore:(bulk standard expedited)"
    "($help)--delete-removed[Delete destination objects with no corresponding source file (for 'sync')]"
    "($help)--no-delete-removed[Don't delete destination objects]"
    "($help)--delete-after[Perform deletes after new uploads (for 'sync')]"
    "($help)--delay-updates[!OBSOLETE! Put all updated files into place at end (for 'sync')]"
    "($help)--max-delete=[Do not delete more than NUM files (for 'del' and 'sync')]:files count: "
    "($help)--limit=[Limit number of objects returned in the response body (only for 'ls' and 'la' commands)]:limit: "
    "($help)*--add-destination=[Additional destination for parallel uploads, in addition to last arg. May be repeated]:destination: "
    "($help)--delete-after-fetch[Delete remote objects after fetching to local file (only for 'get' and 'sync' commands)]"
    "($help -p --preserve)"{-p,--preserve}"[Preserve filesystem attributes (mode, ownership, timestamps). Default for 'sync' command]"
    "($help)--no-preserve[Don't store FS attributes]"
    "($help)--exclude=[Filenames and paths matching GLOB will be excluded from sync]:glob pattern: "
    "($help)--exclude-from=[Read --exclude GLOBs from FILE]:file:_files"
    "($help)--rexclude=[Filenames and paths matching REGEXP (regular expression) will be excluded from sync]:regexp: "
    "($help)--rexclude-from=[Read --rexclude REGEXPs from FILE]:file:_files"
    "($help)--include=[Filenames and paths matching GLOB will be included even if previously excluded by one of --(r)exclude(-from) patterns]:glob pattern: "
    "($help)--include-from=[Read --include GLOBs from FILE]:file:_files"
    "($help)--rinclude=[Same as --include but uses REGEXP (regular expression) instead of GLOB]:regexp: "
    "($help)--rinclude-from=[Read --rinclude REGEXPs from FILE]:file:_files"
    "($help)--files-from=[Read list of source-file names from FILE. Use - to read from stdin]:file:_files"
    "($help --region --bucket-location)"{--region,--bucket-location}"=[Region to create bucket in]:region:(us-east-1 us-west-1 us-west-2 eu-west-1 eu-central-1 ap-northeast-1 ap-southeast-1 ap-southeast-2 sa-east-1)"
    "($help)--host=[HOSTNAME:PORT for S3 endpoint (default: s3.amazonaws.com, alternatives such as s3-eu-west-1.amazonaws.com). You should also set --host-bucket]:host: "
    "($help)--host-bucket=[DNS-style bucket+hostname:port template for accessing a bucket (default: %(bucket)s.s3.amazonaws.com)]:host: "
    "($help --rr --reduced-redundancy)"{--rr,--reduced-redundancy}"[Store object with 'Reduced redundancy'. Lower per-GB price (for 'put', 'cp', 'mv')]"
    "($help --no-rr --no-reduced-redundancy)"{--no-rr,--no-reduced-redundancy}"[Store object without 'Reduced redundancy'. Higher per-GB price (for 'put', 'cp', 'mv')]"
    "($help)--storage-class=[Store object with specified CLASS. Lower per-GB price (for 'put', 'cp', 'mv')]:class:(STANDARD STANDARD_IA REDUCED_REDUNDANCY)"
    "($help)--access-logging-target-prefix=[Target prefix for access logs (S3 URI) (for 'cfmodify' and 'accesslog')]:prefix: "
    "($help)--no-access-logging[Disable access logging (for 'cfmodify' and 'accesslog')]"
    "($help)--default-mime-type=[Default MIME-type for stored objects. Application default is binary/octet-stream]:mime type: "
    "($help -M --guess-mime-type)"{-M,--guess-mime-type}"[Guess MIME-type of files by their extension or mime magic. Fall back to default MIME-Type as specified by --default-mime-type option]"
    "($help)--no-guess-mime-type[Don't guess MIME-type and use the default type instead]"
    "($help)--no-mime-magic[Don't use mime magic when guessing MIME-type]"
    "($help -m --mime-type)"{-m,--mime-type}"=[Force MIME-type. Override both --default-mime-type and --guess-mime-type]:mime type: "
    "($help)*--add-header=[Add a given HTTP header to the upload request - NAME:VALUE. Can be used multiple times]:http header: "
    "($help)*--remove-header=[Remove a given HTTP header. Can be used multiple times (for 'modify')]:http header name: "
    "($help)--server-side-encryption[Specifies that server-side encryption will be used when putting objects (for 'put', 'sync', 'cp', 'modify']"
    "($help)--server-side-encryption-kms-id=[Specifies the key id used for server-side encryption with AWS KMS-Managed Keys (SSE-KMS) when putting objects (for 'put', 'sync', 'cp', 'modify')]:kms key: "
    "($help)--encoding=[Override autodetected terminal and filesystem encoding (character set). Autodetected: UTF-8]:encoding: "
    "($help)--add-encoding-exts=[Add encoding to these comma delimited extensions i.e. (css,js,html) when uploading to S3]:extensions: "
    "($help)--verbatim[Use the S3 name as given on the command line. No pre-processing, encoding, etc. Use with caution!]"
    "($help)--disable-multipart[Disable multipart upload on files bigger than --multipart-chunk-size-mb]"
    "($help)--multipart-chunk-size-mb=[Size of each chunk of a multipart upload. SIZE is in MB, default: 15MB, minimum: 5MB, maximum: 5GB]:chunk size: "
    "($help)--list-md5[Include MD5 sums in bucket listings (only for 'ls')]"
    "($help -H --human-readable-sizes)"{-H,--human-readable-sizes}"[Print sizes in human readable form (eg 1kB instead of 1234)]"
    "($help)--ws-index=[Name of index-document (only for 'ws-create')]:website index: "
    "($help)--ws-error=[Name of error-document (only for 'ws-create')]:website error: "
    "($help)--expiry-date=[Indicates when the expiration rule takes effect (only for 'expire')]:date: "
    "($help)--expiry-days=[Indicates the number of days after object creation the expiration rule takes effect (only for 'expire')]:days: "
    "($help)--expiry-prefix=[Identifying one or more objects with the prefix to which the expiration rule applies (only for 'expire')]:prefix: "
    "($help)--progress[Display progress meter (default on TTY)]"
    "($help)--no-progress[Don't display progress meter (default on non-TTY)]"
    "($help)--stats[Give some file-transfer stats]"
    "($help)--enable[Enable given CloudFront distribution (only for 'cfmodify')]"
    "($help)--disable[Disable given CloudFront distribution (only for 'cfmodify')]"
    "($help)--cf-invalidate[Invalidate the uploaded filed in CloudFront]"
    "($help)--cf-invalidate-default-index[When using Custom Origin and S3 static website, invalidate the default index file]"
    "($help)--cf-no-invalidate-default-index-root[When using Custom Origin and S3 static website, don't invalidate the path to the default index file]"
    "($help)--cf-add-cname=[Add given CNAME to a CloudFront distribution (only for 'cfcreate' and 'cfmodify')]:cname: "
    "($help)--cf-remove-cname=[Remove given CNAME from a CloudFront distribution (only for 'cfmodify')]:cname: "
    "($help)--cf-comment=[Set COMMENT for a given CloudFront distribution (only for 'cfcreate' and 'cfmodify')]:comment: "
    "($help)--cf-default-root-object=[Set the default root object to return when no object is specified in the URL. Use a relative path (only for 'cfcreate' and 'cfmodify')]:path: "
    "($help -v --verbose)"{-v,--verbose}"[Enable verbose output]"
    "($help -d --debug)"{-d,--debug}"[Enable debug output]"
    "(: -)--version[Show s3cmd version and exit]"
    "($help -F --follow-symlinks)"{-F,--follow-symlinks}"[Follow symbolic links as if they are regular files]"
    "($help)--cache-file=[Cache FILE containing local source MD5 values]:file:_files"
    "($help -q --quiet)"{-q,--quiet}"[Silence output on stdout]"
    "($help)--ca-certs=[Path to SSL CA certificate FILE (instead of system default)]:file:_files"
    "($help)--check-certificate[Check SSL certificate validity]"
    "($help)--no-check-certificate[Do not check SSL certificate validity]"
    "($help)--check-hostname[Check SSL certificate hostname validity]"
    "($help)--no-check-hostname[Do not check SSL certificate hostname validity]"
    "($help)--signature-v2[Use AWS Signature version 2 instead of newer signature methods]"
    "($help)--limit-rate=[Limit the upload or download speed to amount bytes per second. Amount may be expressed in bytes, kilobytes with the k suffix, or megabytes with the m suffix]:limit: "
    "($help)--requester-pays[Set the REQUESTER PAYS flag for operations]"
    "($help -l --long-listing)"{-l,--long-listing}"[Produce long listing (for 'ls')]"
    "($help)--stop-on-error[Stop if error in transfer]"
    "($help)--content-disposition=[Provide a Content-Disposition for signed URLs]:content disposition: "
    "($help)--content-type=[Provide a Content-Type for signed URLs]"
  )

  _arguments -C $_options \
    "($help -): :->command" \
    "($help -)*:: :->argument" && ret=0

  case $state in
  command)
    _command && ret=0
    ;;
  argument)
    curcontext=${curcontext%:*:*}:s3cmd-$words[1]:
    _command_argument && ret=0
    ;;
  esac

  return ret
}

alias sls='s3cmd ls'
alias spt='s3cmd --recursive put'
alias sgt='s3cmd --recursive get'
alias srm='s3cmd rm'

compdef _s3cmd s3cmd
