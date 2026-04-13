function kumo --description 'Inicia o kumo em segundo plano'
    docker run -d \
      --name kumo-server \
      -p 4566:4566 \
      -e KUMO_DATA_DIR=/tmp/kumo/data \
      -v kumo-data:/tmp/kumo/data \
      ghcr.io/sivchari/kumo:latest $argv
end
