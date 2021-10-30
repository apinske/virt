#/bin/sh
if [ "$1" == "all" ]; then
  find . -name 'config-linux-*' -exec sh -c 'cat $0 | sed -e "s/# //" | grep CONFIG_ | sort -u > diff-$(basename $0)' {} \; 
else
  find . -name 'config-linux-*' -exec sh -c 'cat $0 | grep -v "# " | grep CONFIG_ | sort -u > diff-$(basename $0)' {} \; 
fi
opendiff diff-config-linux-*
rm diff-config-linux-*
