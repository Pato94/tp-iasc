# Usage example: bash post.sh 1 unmensaje
curl -XPOST localhost:4001/push/$1 -H "Content-type: application/json" -d '{"message": '\""$2"\"'}'