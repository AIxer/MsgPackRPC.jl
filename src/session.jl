mutable struct RPCSession{S}
    sock::S
    msgid::Int
    RPCSession(addr::IPAddr, port::Integer) = new(connect(addr, port), 1)
    RPCSession(port::Integer) = new(connect(port), 1)
end

Base.close(s::RPCSession) = close(s.sock)

function call(session, method, params...; timeout=0, interval=0.001)
    msgid = session.msgid
    session.msgid += 1
    msg = pack([REQUEST, msgid, method, params])
    write(session.sock, msg)
    res = recvbytes(session.sock; timeout, interval) |> unpack
    isnothing(res) && return nothing
    # [1, msgid, error, result]
    @inbounds if res[1] != 1 || res[2] != msgid || !isnothing(res[3])
        # TODO throw error?
        nothing
    else
        res[4]
    end
end

function recvbytes(sock; timeout=0, interval=0.001)
    res = nothing
    t = @async res = readavailable(sock)
    times = div(timeout, interval)
    while times > 0
        sleep(interval)
        !isnothing(res) && return res
        times -= 1
    end
    isnothing(res) && Base.throwto(t, InterruptException())
    nothing
end


