 (cd "$(git rev-parse --show-toplevel)" && git apply --3way <<'EOF' 
diff --git a/README.md b/README.md
index 0f1d0fc9b6ddf29c920eda94e0db895141a069e9..df39187608bb466075c94a9e219e962832b90402 100644
--- a/README.md
+++ b/README.md
@@ -1,50 +1,88 @@
-A server app built using [Shelf](https://pub.dev/packages/shelf),
-configured to enable running with [Docker](https://www.docker.com/).
+# Sympllizy Back
 
-This sample code handles HTTP GET requests to `/` and `/echo/<message>`
+API de autenticação e controle de acesso construída com [Shelf](https://pub.dev/packages/shelf), PostgreSQL e JWT. O servidor expõe documentação OpenAPI/Swagger, middlewares para logging/CORS e rotas protegidas por roles.
 
-# Running the sample
+## Visão geral da arquitetura
+- **Entrada do servidor**: `bin/server.dart` carrega variáveis de ambiente, configurações e inicia o servidor HTTP.
+- **Camada core**: `lib/core/` centraliza configuração (`AppConfig`), acesso a banco (`DatabaseConnection`, `DB`), middlewares (CORS, logger, contexto), utilitários HTTP e segurança (JWT).
+- **Módulos de domínio**: `lib/modules/` agrupa funcionalidades; o módulo `auth` implementa repositório, serviço, controlador e rotas de autenticação.
+- **Servidor e rotas**: `lib/server/server.dart` registra middlewares globais, rotas protegidas (`/me`, `/admin`) e handlers de documentação/health check.
 
-## Running with the Dart SDK
+## Requisitos
+- Dart SDK 3+
+- PostgreSQL acessível via URL de conexão
+- Docker (opcional para containerizar)
 
-You can run the example with the [Dart SDK](https://dart.dev/get-dart)
-like this:
+### Variáveis de ambiente
+Crie um arquivo `.env` na raiz do projeto (obrigatório) com as chaves:
 
-```
-$ dart run bin/server.dart
-Server listening on port 8080
+| Variável | Descrição |
+| --- | --- |
+| `APP_ENV` | Ambiente (`dev`, `staging`, `prod`) controlando flags de debug/log.
+| `PORT` | Porta HTTP (padrão `8080`).
+| `DATABASE_URL` | URL de conexão PostgreSQL.|
+| `JWT_SECRET` | Segredo para assinar tokens JWT.
+| `JWT_ISSUER` | Issuer utilizado na assinatura/verificação dos tokens.
+
+Exemplo de `.env`:
+```env
+APP_ENV=dev
+PORT=8080
+DATABASE_URL=postgres://user:pass@localhost:5432/sympllizy
+JWT_SECRET=super-secret-key
+JWT_ISSUER=sympllizy-api
 ```
 
-And then from a second terminal:
+## Como rodar
+### Dart SDK
+```bash
+dart run bin/server.dart
 ```
-$ curl http://0.0.0.0:8080
-Hello, World!
-$ curl http://0.0.0.0:8080/echo/I_love_Dart
-I_love_Dart
+O servidor ficará disponível em `http://localhost:${PORT}`.
+
+### Docker
+```bash
+docker build . -t sympllizy_back
+docker run -it -p 8080:8080 --env-file .env sympllizy_back
 ```
 
-## Running with Docker
+## Rotas principais
+### Autenticação (`/auth`)
+- `POST /auth/signup` – Cria organização, usuário owner e empresa matriz, retornando par de tokens.
+- `POST /auth/login` – Autentica com e-mail/senha e retorna tokens.
+- `POST /auth/refresh` – Gera novo par de tokens a partir do refresh token válido.
+- `POST /auth/logout` – Revoga o refresh token atual (requer Bearer token + refresh no corpo).
 
-If you have [Docker Desktop](https://www.docker.com/get-started) installed, you
-can build and run with the `docker` command:
+Exemplos rápidos:
+```bash
+# Signup
+curl -X POST http://localhost:8080/auth/signup \
+  -H "Content-Type: application/json" \
+  -d '{"org_name":"Minha Empresa","email":"admin@empresa.com","password":"senha123"}'
 
-```
-$ docker build . -t myserver
-$ docker run -it -p 8080:8080 myserver
-Server listening on port 8080
+# Login
+ACCESS_TOKEN=$(curl -s -X POST http://localhost:8080/auth/login \
+  -H "Content-Type: application/json" \
+  -d '{"email":"admin@empresa.com","password":"senha123"}' | jq -r '.data.access_token')
 ```
 
-And then from a second terminal:
-```
-$ curl http://0.0.0.0:8080
-Hello, World!
-$ curl http://0.0.0.0:8080/echo/I_love_Dart
-I_love_Dart
-```
+### Rotas protegidas
+- `GET /me` – Retorna dados do usuário autenticado (Bearer access token obrigatório).
+- `POST /admin/stats` – Exige role `admin` além do JWT; retorna payload simples de ok.
 
-You should see the logging printed in the first terminal:
-```
-2021-05-06T15:47:04.620417  0:00:00.000158 GET     [200] /
-2021-05-06T15:47:08.392928  0:00:00.001216 GET     [200] /echo/I_love_Dart
+Uso com token obtido no login:
+```bash
+curl -H "Authorization: Bearer $ACCESS_TOKEN" http://localhost:8080/me
 ```
-# sympllizy_back
+
+### Saúde e documentação
+- `GET /health` – Health check simples com timestamp.
+- `GET /openapi.json` – Esquema OpenAPI gerado dinamicamente.
+- `GET /docs` – UI Swagger servida a partir do schema acima.
+
+## Observabilidade e middlewares
+O pipeline HTTP inclui logging de requests/consultas, CORS, contexto de organização e validação de JWT via middlewares globais antes das rotas registradas. Isso garante rastreabilidade em logs e respostas JSON consistentes via `ApiResponse` e handler de erros padrão.
+
+## Desenvolvimento
+- A configuração de ambiente é carregada no início do processo; faltas de variáveis obrigatórias lançam exceção.
+- O OpenAPI está acoplado às rotas via `OpenApi.addOperation`, permitindo manter a documentação sempre sincronizada com o código.
 
EOF
)