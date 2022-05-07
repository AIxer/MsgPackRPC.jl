module MsgPackRPC

using Sockets
using MsgPack

export RPCSession, call

const REQUEST  = 0  # [0, msgid, method, param]
const RESPONSE = 1  # [1, msgid, error, result]
const NOTIFY   = 2  # [2, method, param]

include("session.jl")

end # module