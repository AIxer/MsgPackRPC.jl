mutable struct RPCSession{S}
    sock::S
    msgid::Int
end

RPCSession(port::Integer) = RPCSession(connect(port), 1)
RPCSession(addr::IPAddr, port::Integer) = RPCSession(connect(addr, port), 1)

Base.close(s::RPCSession) = close(s.sock)

function call(session, method, params...; timeout=0.001, interval=0.001)
    msgid = session.msgid
    session.msgid += 1
    msg = pack([REQUEST, msgid, method, params])
    write(session.sock, msg)
    res = unpack(readavailable(session.sock))
    # [1, msgid, error, result]
    @inbounds if res[1] != 1 || res[2] != msgid || !isnothing(res[3])
        # TODO throw error?
        nothing
    else
        res[4]
    end
end

function recvbytes(sock; timeout=0.001, interval=0.001)
    res = nothing
    ch = Channel{Bool}(1)
    t = @async begin
        isready(ch) && return
        res = readavailable(sock)
    end
    times = Int(timeout / interval)
    while times > 0
        sleep(interval)
        istaskdone(t) && return res
        times -= 1
    end
    put!(ch, true)
    return res
end


