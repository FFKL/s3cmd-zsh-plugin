function _command() {
  integer ret=1
  local -a _commands=(
    'ls:List objects or buckets'
    'la:List all object in all buckets'
    'mb:Make bucket'
    'put:Put file into bucket'
  )
  _describe -t commands 'command' _commands && ret=0

  return ret
}

function _bucket() {
  integer ret=1
  local -a _buckets
  _buckets=($(s3cmd ls | grep -o 's3://\S*' | tr '\n' ' ' | sed 's!s3://!!g'))
  compadd -P 's3://' -a _buckets && ret=0

  return ret
}

function _command_argument() {
  integer ret=1
  case "$words[1]" in
  ls)
    _arguments "1:bucket:_bucket" && ret=0
    ;;
  put)
    _arguments "1:filepath:_files" "2:bucket:_bucket" && ret=0
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

compdef _s3cmd s3cmd
