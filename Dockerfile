FROM node:lts-alpine as frontend

WORKDIR /frontend-build

COPY web/package.json web/yarn.lock ./
RUN yarn install

COPY web ./
RUN yarn build

FROM golang:1.17-alpine as backend

RUN apk add --no-cache gcc musl-dev linux-headers

WORKDIR /backend-build

COPY go.* ./
RUN go mod download

COPY . .
COPY --from=frontend /frontend-build/dist web/dist

RUN go build -o eth-faucet -ldflags "-s -w"

FROM alpine

RUN apk add --no-cache ca-certificates

COPY --from=backend /backend-build/eth-faucet /app/eth-faucet

EXPOSE 8080

ENTRYPOINT ["/app/eth-faucet"]
CMD ["-httpport", "8080", "-proxycount", "0", "-faucet.amount", "1", "-faucet.minutes", "1440", "-faucet.name", "testnet", "-faucet.symbol", "ETH", "-hcaptcha.sitekey", "", "-hcaptcha.secret", ""]
