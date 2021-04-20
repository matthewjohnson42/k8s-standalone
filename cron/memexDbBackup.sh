set -x
FILE_NAME="${ARCHIVE_DIR}/$(date +%Y%m%d%H%M%S).tar.gz"
echo
echo "[INFO] Beginning backup to ${FILE_NAME}"
sudo tar -c "${MONGO_DIR}" | gzip > "${FILE_NAME}";
cd ${ARCHIVE_DIR};
archives=($(ls | sort -r));
count=0;
while [ ${count} -lt ${#archives[@]} ]; do
  if [ ${count} -gt ${ARCHIVE_LIMIT} ]; then
    rm ${archives[${count}]};
  fi;
  count=$((${count}+1));
done
echo "[INFO] End backup to ${FILE_NAME}"
echo
