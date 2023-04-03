#!/bin/bash

# No site da UFGD esse domínio é usado só pra ser redirecionado
second_link='https://sigecad-academico.ufgd.edu.br'

main_link='https://login.ufgd.edu.br/login_form'
third_link='https://ufgdnet.ufgd.edu.br/perfil/'

# "Response Header"
response=$(
   curl -s --insecure -iL  "${second_link}" -w '%{header_json}' \
      -o /tmp/response.json | jq -r
)

set_cookie=$(jq -r '.["set-cookie"]' <<< "$response")

# PLAY_SESSION e ___AT são valores necessários para obter o token UFGDNET
play_session=$(grep -Po '(?<=PLAY_SESSION=)[a-z0-9]{40}' <<< "$set_cookie")
at=$(grep -Po '(?<=AT=)[a-z0-9]{40}' <<< "$set_cookie")

cookie="PLAY_SESSION=${play_session}-___AT=${at}"

# Esse User-Agent é aleatório, mude pra outro se quiser
user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) \
AppleWebKit/537.36 (KHTML, like Gecko) \
Chrome/42.0.2311.135 Safari/537.36 \
Edge/12.246"

# O arquivo credentials.json possui as informações de login,
# mude os dados de exemplo dele pra as suas credenciais.
username=$(jq -r '.username' ./credentials.json)
password=$(jq -r '.password' ./credentials.json)

# Dados que serão utilizados no POST
data="authenticityToken=${play_session}&\
user.username=${username}&\
user.password=${password}"

post_response=$(curl -sS -X POST \
   -w '%{header_json}' \
   --data-raw "$data" \
   --insecure -i "$main_link" \
   --user-agent "$user_agent" \
   --cookie "${cookie}"
)

# Pegando o token UFGDNET e atribuindo as informações de usuário
# ao fim.
ufgd_net=$(grep -Po '(?<=UFGDNET=)[a-z0-9]{40}' <<< "$post_response")
ufgd_net="${ufgd_net}-${username}"

curl -sS --insecure --user-agent "$user_agent" \
   --cookie "UFGDNET=${ufgd_net}" \
   -iL "$third_link" \
   -o output.zip

# Removendo informações de cabeçalho da requisição GET
sed -i '1,/^[[:space:]]*$/d' output.zip

# Visualizando os dados da saída que esta em formato gzip
zcat output.zip
