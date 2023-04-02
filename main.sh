# No site da UFGD esse domínio é usado só pra ser redirecionado
main_link='sigecad-academico.ufgd.edu.br'

# "Response Header"
response=$(
   curl -s --insecure -iL  "${main_link}" -w '%{header_json}' \
      -o /tmp/response.json | jq -r
)

set_cookie=$(jq -r '.["set-cookie"]' <<< "$response")

# PLAY_SESSION e ___AT são valores necessários para obter o token UFGDNET
play_session=$(grep -Po '(?<=PLAY_SESSION=)[a-z0-9]{40}' <<< "$set_cookie")
at=$(grep -Po '(?<=AT=)[a-z0-9]{40}' <<< "$set_cookie")

cookie=""
