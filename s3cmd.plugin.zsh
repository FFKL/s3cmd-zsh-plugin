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
    "($help -c --config)"{-c,--config}"=[Config file name. Defaults to \$HOME/.s3cfg]"
    "(: -)--dump-config[Dump current configuration after parsing config files and command line options and exit]"
    "($help)--access_key=[AWS Access Key]"
    "($help)--secret_key=[AWS Secret Key]"
    "($help)--access_token=[AWS Access Token]"
    "($help -n --dry-run)"{-n,--dry-run}"[Only show what should be uploaded or downloaded but don't actually do it]"
    "($help -s --ssl)"{-s,--ssl}"[Use HTTPS connection when communicating with S3 (default)]"
    "($help)--no-ssl[Don't use HTTPS]"
    "($help -e --encrypt)"{-e,--encrypt}"[Encrypt files before uploading to S3]"
    "($help)--no-encrypt[Don't encrypt files]"
    "($help -f --force)"{-f,--force}"[Force overwrite and other dangerous operations]"
    "($help)--continue[Continue getting a partially downloaded file (only for 'get' command)]"
    "($help)--continue-put[Continue uploading partially uploaded files or multipart upload parts]"
    "($help)--upload-id=[UploadId for Multipart Upload, in case you want to continue an existing upload]"
    "($help)--skip-existing[Skip over files that exist at the destination (only for 'get' and 'sync' commands)]"
    "($help -r --recursive)"{-r,--recursive}"[Recursive upload, download or removal]"
    "($help)--check-md5[Check MD5 sums when comparing files for 'sync' (default)]"
    "($help)--no-check-md5[Do not check MD5 sums when comparing files for 'sync']"
    "($help -P --acl-public)"{-P,--acl-public}"[Store objects with ACL allowing read for anyone]"
    "($help)--acl-private[Store objects with default ACL allowing access for you only]"
    "($help)--acl-grant=[Grant stated permission to a given amazon user]:permissions:(read write read_acp write_acp full_control all)"
    "($help)--acl-revoke=[Revoke stated permission for a given amazon user]:permissions:(read write read_acp write_acp full_control all)"
    "($help -D --restore-days)"{-D,--restore-days}"=[Number of days to keep restored file available (only for 'restore' command)]"
    "($help)--restore-priority[Priority for restoring files from S3 Glacier (only for 'restore' command)]:restore:(bulk standard expedited)"
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
