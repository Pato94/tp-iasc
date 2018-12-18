# Usage example: bash start_slave.sh 1
iex --sname slave$1 --erl "-config config/db.config" -S mix run