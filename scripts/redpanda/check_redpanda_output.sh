docker compose -p elixir-conf-2023-broadway-training \
    exec redpanda /bin/bash \
    rpk topic consume postgres.public.transactions
