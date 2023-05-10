
module Drawables

using ..Cairo
using ..BoxPoints: Point


export Drawable, ImageDrawable, PDFDrawable, RecorderDrawable, SVGDrawable, close, paint, save




##############################################################################
abstract type Drawable
end

mutable struct ImageDrawable <: Drawable
    surface
    ctx
    width
    height
    fname
end


mutable struct PDFDrawable <: Drawable
    surface
    ctx
    width
    height
    fname
end

mutable struct SVGDrawable <: Drawable
    surface
    ctx
    width
    height
    fname
end

mutable struct RecorderDrawable <: Drawable
    surface
    ctx
    width
    height
end


##############################################################################
# surface functions

"""
    makerecordingsurface(width, height)

Create a Cairo recording surface.
"""
function RecorderDrawable(width, height)
    surface = CairoRecordingSurface(Cairo.CONTENT_COLOR_ALPHA,
                                    Cairo.CairoRectangle(0,0,width,height))
    ctx = CairoContext(surface)
    return RecorderDrawable(surface, ctx, width, height)
end


"""
     makepdfsurface(width, height, fname)

Create a Cairo surface for writing to pdf file fname.
"""
function PDFDrawable(width, height, fname)
    surface = CairoPDFSurface(fname, width, height)
    ctx = CairoContext(surface)
    return PDFDrawable(surface, ctx, width, height, fname)
end



"""
     makesvgsurface(width, height, fname)

Create a Cairo surface for writing to svg file fname.
"""
function SVGDrawable(width, height, fname)
    surface = CairoSVGSurface(fname, width, height)
    ctx = CairoContext(surface)
    return SVGDrawable(surface, ctx, width, height, fname)
end


"""
    makepngsurface(width, height)

Create a Cairo surface for writing to a png file.
"""
function ImageDrawable(width, height, fname)
    surface = CairoARGBSurface(width, height)
    ctx = CairoContext(surface)
    return ImageDrawable(surface, ctx, width, height, fname)
end


"""
    Drawable(width, height, fname)

Create a Cairo surface with given width/height. Determine type from the file extension.
"""
function Drawable(width, height; fname = nothing)
    if isnothing(fname)
        return RecorderDrawable(width, height)
    end
    
    if lowercase(fname[end-2:end]) == "png"
        return  ImageDrawable(width, height, fname)
    end

    if lowercase(fname[end-2:end]) == "svg"
        return SVGDrawable(width, height, fname)
    end
    
    if lowercase(fname[end-2:end]) == "pdf"
        return PDFDrawable(width, height, fname)
    end

    println("ERROR: need valid filename to create drawable")
end

"""
    closedrawable(dw::Drawable)

Close the Cairo surface and write output.
"""
function Base.close(dw::Drawable) 
    finish(dw.surface)
    destroy(dw.surface)
    destroy(dw.ctx)
end

function Base.close(dw::ImageDrawable)
    write_to_png(dw.surface, dw.fname)
    finish(dw.surface)
    destroy(dw.surface)
    destroy(dw.ctx)
end


##############################################################################
# output a RecorderDrawable


# output to a context
# p = location of top-left of r in destination coords
function Cairo.paint(ctx::CairoContext, r::RecorderDrawable, p = Point(0,0), scalefactor = 1.0)
    save(ctx)
    scale(ctx, scalefactor, scalefactor)
    set_source_surface(ctx, r.surface, p.x/scalefactor, p.y/scalefactor)
    paint(ctx)
    restore(ctx)
end
Cairo.paint(dest::Drawable, args...) = paint(dest.ctx, args...)


# output to a file
function Cairo.save(r::RecorderDrawable, fname, scale=1)
    dw = Drawable(scale*r.width, scale*r.height; fname)
    Cairo.scale(dw.ctx, scale, scale)
    paint(dw, r)
    close(dw)
end

##############################################################################

end
