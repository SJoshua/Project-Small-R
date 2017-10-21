-------------------------------------------
-- Project Small R
-- Telegram Bot API
-- Au: SJoshua
-------------------------------------------
bot = {}

-------------------------------------------
-- function @ makeRequest
-- All queries to the Telegram Bot API must be served over HTTPS and need to be presented in this form:
-- > https://api.telegram.org/bot<token>/METHOD_NAME.
-- We support GET and POST HTTP methods. We support four ways of passing parameters in Bot API requests:
-- * URL query string
-- * application/x-www-form-urlencoded
-- * application/json (except for uploading files)
-- * multipart/form-data (use to upload files)
-------------------------------------------
function makeRequest(method, body)
end

function bot.run(token)
end
