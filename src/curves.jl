
module Curves

using ..BoxPoints: Point

export Bezier, point, tangent, point_and_tangent


mutable struct Bezier
    p0
    p1
    p2
    p3
end

##############################################################################
# bezier curves

"""
    Bezier(p1:;Point, p2::Point, theta1, theta2, r)

Construct bezier control points for a curve from p1 to p2 with departure angles and parameter.
"""
function Bezier(p1::Point, p2::Point, theta1, theta2, r)
    u = (p2-p1)/norm(p2-p1)
    T = [u.x -u.y ; u.y  u.x]
    r0 = r * norm(p2-p1)
    c0 = p1
    c1 = p1 + T*polar(r0, theta1)
    c2 = p2 - T*polar(r0, -theta2)
    c3 = p2
    return Bezier(c0, c1, c2, c3)
end

"""
    cut(B::Bezier, t)

Returns two Beziers b1 and b2 such that b1 is the [0,t] segment
of the supplied curve, and b2 is the [t,1] segment.
"""
function cut(B::Bezier, t)
    e = interp(B.p0, B.p1, t)
    f = interp(B.p1, B.p2, t)
    g = interp(B.p2, B.p3, t)
    h = interp(e, f, t)
    j = interp(f, g, t)
    k = interp(h, j, t)
    return Bezier(B.p0, e, h, k), Bezier(k, j, g, B.p3)
end


"""
     point(B::Bezier, t)

Return the point at position t along the bezier curve B
"""
function point(B::Bezier, t)
    b = (1-t)^3 * B.p0 + 3*(1-t)^2*t*B.p1 + 3*(1-t)*t^2*B.p2 + t^3 * B.p3
    return b
end

"""
     tangent(B::Bezier, t)

Return the tangent at position t along the bezier curve B
"""
function tangent(B::Bezier, t)
    bt = 3*(1-t)^2 *(B.p1 - B.p0) + 6*(1-t)*t*(B.p2 - B.p1) + 3*t*t*(B.p3 - B.p2)
end

"""
     point_and_tangent(args...)

Return the position and tangent at position t along the curve or line
"""
point_and_tangent(args...) = point(args...), tangent(args...)

#######################################################################################
# lines

function point(points::Vector{Point}, alpha)
    if alpha == 0
        return points[1]
    elseif alpha == 1
        return points[end]
    end
    # TODO
    println("ERROR: cannot interpolate polyline")
end

function tangent(points::Vector{Point}, alpha)
    if alpha == 0
        p1 = points[1]
        p2 = points[2]
        # TODO should this be normalized?
        return Point(p2.x - p1.x, p2.y - p1.y)
    elseif alpha == 1
        p1 = points[end-1]
        p2 = points[end]
        return Point(p2.x - p1.x, p2.y - p1.y)
    end
    println("ERROR: cannot interpolate polyline")
end





end
