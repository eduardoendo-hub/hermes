# Setup do Hermes via Coolify — passo a passo

## Pré-requisitos

- Coolify rodando e acessível
- Um "Server" no Coolify com pelo menos **8GB RAM** disponível (rails + sidekiq + pg + redis comem ~5GB em uso normal)
- Domínio `hermes.technowhub.ai` apontando para o IP do Server (registro A)
- Acesso SSH ao Server (vamos precisar pra sincronizar logos no volume `branding`)

---

## Passo 1 — Criar o projeto

1. Coolify UI → **Projects** → **New Project**
2. Nome: `Hermes`
3. Description: `Tela de atendimento WhatsApp da Tech Now (Chatwoot whitelabel)`
4. Selecione um **Server** (com 8GB+ disponível)

---

## Passo 2 — Adicionar o resource Docker Compose

1. Dentro do projeto Hermes → **+ New Resource** → **Docker Compose Empty**
2. Nome: `chatwoot`
3. Server: o mesmo do projeto
4. **Docker Compose** → cole o conteúdo de `coolify/chatwoot-stack.yml`
5. **Save**

---

## Passo 3 — Configurar domínio (Traefik + LE automático)

1. Na resource `chatwoot` → **Domains for rails**:
   - `https://hermes.technowhub.ai`
2. Salvar. Coolify detecta `SERVICE_FQDN_RAILS_3000` e cria as rotas Traefik + emite cert Let's Encrypt automaticamente.

---

## Passo 4 — Verificar variáveis mágicas

Em **Environment Variables** da resource, confirme que existem (geradas pelo Coolify):

- `SERVICE_FQDN_RAILS_3000` (URL do rails)
- `SERVICE_PASSWORD_POSTGRES`
- `SERVICE_PASSWORD_REDIS`
- `SERVICE_BASE64_64_SECRETKEYBASE`

Se faltar alguma, clique **Regenerate** ou crie manualmente seguindo a sintaxe Coolify.

---

## Passo 5 — Primeiro deploy

1. Clique **Deploy**
2. Acompanhe os logs (rails sobe em ~90s; sidekiq em paralelo)
3. Aguarde **rails** e **sidekiq** marcados como `healthy`

---

## Passo 6 — Inicializar banco de dados

Coolify → resource `chatwoot` → **Terminal** → escolha container `rails`:

```bash
bundle exec rails db:chatwoot_prepare
```

Depois force restart dos serviços `rails` e `sidekiq` (Coolify → Restart).

---

## Passo 7 — Criar admin

1. Abrir `https://hermes.technowhub.ai`
2. Primeiro signup vira **super admin** automaticamente
3. Crie a conta `admin@technowhub.ai` (ou e-mail seu)

---

## Passo 8 — Subir logos no volume `branding`

O volume `branding` foi criado vazio. Pra preencher, no laptop:

```bash
./scripts/sync-branding.sh <coolify-server-ssh-host>
```

(Veja `scripts/sync-branding.sh` — usa `docker cp` via SSH no host do Coolify.)

Depois, no Chatwoot UI:
- Settings → **General** → **Custom CSS** → cole o conteúdo de `branding/custom.css`
- Cmd+Shift+R pra ver Tiffany/Rose aplicadas

---

## Passo 9 — Conectar WhatsApp Cloud API

1. **Settings → Inboxes → Add Inbox → WhatsApp → WhatsApp Cloud**
2. Preencha:
   - Phone Number ID
   - WhatsApp Business Account ID
   - API Key (System User Token permanente)
3. Chatwoot devolve **Webhook URL** + **Verify Token** — copie.
4. Meta App Dashboard → seu app → WhatsApp → Configuration:
   - Callback URL = o do Chatwoot
   - Verify Token = o do Chatwoot
   - Subscribe a: `messages`, `message_template_status_update`
5. Atribua o número ao app (uma vez):

```bash
curl -X POST \
  "https://graph.facebook.com/v20.0/<WABA_ID>/subscribed_apps" \
  -H "Authorization: Bearer <SYSTEM_USER_TOKEN>"
```

---

## Passo 10 — Teste round-trip

- Mande "oi" do seu celular pro número conectado → conversa aparece no Chatwoot
- Responda no Chatwoot → chega no celular

Se falhar, no Coolify abra logs do container `sidekiq` (jobs do canal WhatsApp passam por lá) e `rails`.

---

## Troubleshooting Coolify-específico

| Sintoma | Causa | Fix |
|---|---|---|
| Cert não emite | Domínio ainda não propagou | `dig hermes.technowhub.ai`; aguarde 5min; Coolify retenta sozinho |
| `rails` reinicia em loop | DB ainda não inicializado | Rodar `db:chatwoot_prepare` (Passo 6) |
| Logos não aparecem | Volume `branding` vazio | Rodar `scripts/sync-branding.sh` (Passo 8) |
| Mudança de env var não pega | Coolify exige rebuild | Resource → **Stop** → **Deploy** (não só restart) |
| `502 Bad Gateway` no Traefik | rails health check ainda falhando | Aguarde 2min após deploy; ver logs |
