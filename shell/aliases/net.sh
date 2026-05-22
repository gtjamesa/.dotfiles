#!/bin/bash

# Get external IP address
alias ipaddr='curl ipecho.net/plain; echo'

reqtime() {
  FORMAT=" \
    time_namelookup:  %{time_namelookup}\n \
       time_connect:  %{time_connect}\n \
    time_appconnect:  %{time_appconnect}\n \
   time_pretransfer:  %{time_pretransfer}\n \
      time_redirect:  %{time_redirect}\n \
 time_starttransfer:  %{time_starttransfer}\n \
                    ----------\n \
         time_total:  %{time_total}\n"

  curl -sk -o /dev/null -w "$FORMAT" "$1" "${@:2}"
}

speedtest() {
  curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
}

speedtest-linode() {
  # https://gist.github.com/raulmoyareyes/34cbd643e2c93be64746
  # curl -o /dev/null http://speedtest.london.linode.com/1GB-london.bin

  if [[ "$1" == "--help" ]]; then
    cat << EOF
usage: $0 [SIZE]
    --help               Show this message
    SIZE                 Speedtest download size [100MB/1GB]
EOF
    return 0
  fi

  SPEEDTEST_SIZE="$1"

  if [[ -z "$1" ]]; then
    SPEEDTEST_SIZE="100MB"
  fi

  echo "Starting $SPEEDTEST_SIZE download. Available: 100MB / 1GB"

  curl -o /dev/null "http://speedtest.london.linode.com/$SPEEDTEST_SIZE-london.bin"
}
