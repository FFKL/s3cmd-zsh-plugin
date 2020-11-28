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
    {-h,--help}"[show help message and exit]"
    "($help)--configure[Invoke interactive (re)configuration tool]"
    "($help)--access_key=[AWS Access Key]"
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
