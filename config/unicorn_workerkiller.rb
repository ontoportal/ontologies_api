puts "(API) >> Unicorn workerKiller enabled"

  # Unicorn self-process killer
  require 'unicorn/worker_killer'

  # Max requests per worker
  use Unicorn::WorkerKiller::MaxRequests, 10240, 20480

  # Max memory size (RSS) per worker in bytes
  use Unicorn::WorkerKiller::Oom, (2048*(1024**2)), (3072*(1024**2))

