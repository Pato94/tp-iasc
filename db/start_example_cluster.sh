iex --sname master -S mix run --no-halt &
iex --sname slave1 --erl "-config config/db.config" -S mix run --no-halt &
iex --sname slave2 --erl "-config config/db.config" -S mix run --no-halt &
iex --sname slave3 --erl "-config config/db.config" -S mix run --no-halt &
iex --sname slave4 --erl "-config config/db.config" -S mix run --no-halt &