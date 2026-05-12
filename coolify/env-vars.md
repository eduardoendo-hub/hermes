# Variáveis de ambiente — Hermes (Chatwoot)

> O `chatwoot-stack.yml` usa **magic variables do Coolify** (`SERVICE_FQDN_*`,
> `SERVICE_PASSWORD_*`, `SERVICE_BASE64_*`). Você **não** precisa preencher
> nada à mão pra elas — Coolify gera no primeiro deploy.

## Variáveis configuráveis (UI Coolify → Environment Variables)

| Var | Default no stack | Quando customizar |
|---|---|---|
| `INSTALLATION_NAME` | `Hermes` | Aparece em e-mails e abas. Mantém. |
| `BRAND_NAME` | `Hermes` | Mantém. |
| `BRAND_URL` | `https://technowhub.ai` | Link clicável a partir do logo. |
| `WIDGET_BRAND_URL` | `https://technowhub.ai` | Link no rodapé do widget de chat embebido. |
| `LOGO` | `/branding/logo.svg` | Path dentro do container. Não mexer. |
| `LOGO_THUMBNAIL` | `/branding/logo-thumbnail.svg` | Idem. |
| `LOGO_DARK` | `/branding/logo-dark.svg` | Idem. |
| `DEFAULT_LOCALE` | `pt_BR` | Mantém — idioma do produto. |
| `ENABLE_ACCOUNT_SIGNUP` | `false` | Mantém `false` em prod. |
| `FORCE_SSL` | `true` | Mantém. |
| `MAILER_SENDER_EMAIL` | `Hermes <hermes@technowhub.ai>` | Atualize quando SMTP entrar. |

## SMTP (V2 — deixar vazio hoje)

Adicione **só quando integrar Mailgun/SES/Postmark**:

```
SMTP_ADDRESS=smtp.mailgun.org
SMTP_PORT=587
SMTP_USERNAME=postmaster@...
SMTP_PASSWORD=...
SMTP_AUTHENTICATION=plain
SMTP_ENABLE_STARTTLS_AUTO=true
```

## WhatsApp Cloud API

**Não vai em variável de ambiente** — vai dentro do Chatwoot na UI:
**Settings → Inboxes → Add → WhatsApp → WhatsApp Cloud**.

Campos pedidos lá:
- Phone Number ID
- Business Account ID (WABA)
- API Key (System User Access Token, permanente)

Após salvar, Chatwoot gera **Webhook URL** e **Verify Token** — copie e cole no
Meta App Dashboard → WhatsApp → Configuration.

## Sanity check

Pós-deploy, o `docker exec` no container `rails`:

```
env | grep -E '(INSTALLATION_NAME|BRAND|LOGO|FRONTEND_URL|POSTGRES_HOST|REDIS_URL)'
```

Os 7 valores acima devem aparecer preenchidos.
