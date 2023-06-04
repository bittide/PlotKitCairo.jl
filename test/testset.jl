
plotpath(x) = joinpath(ENV["HOME"], "plots/", x)


function main()
    @testset "plotkitcairo basic plots" begin
        @test main1()
        @test main2()
        @test main3()
        @test main4()
        @test main5()
        @test main6()
        @test main7()
        @test main8()
    end
end
    
# basic lines
function main1()
    println("main1")
    width = 800
    height = 600
    fname = plotpath("pkcairo1.png")
    # drawing
    dw = Drawable(width, height; fname)
    rect(dw, Point(0,0), Point(800, 600); fillcolor = Color(1,0.8,0.9))
    line(dw, Point(10, 20), Point(800, 450); linestyle = LineStyle(Color(:blue), 5))
    line(dw, Point(10, 500), Point(600, 50); linestyle = LineStyle(Color(0,0.7,0.3), 5))
    close(dw)
    return true
end


function testpattern1(dw, width, height)
    for (i,r) in enumerate(0:20:200)
        rect(dw, Point(r,r), Point(width-2r, height-2r); fillcolor = colormap(i))
    end
end


# basic lines
function main2()
    println("main2")
    width = 800
    height = 600
    fname = plotpath("pkcairo2.pdf")
    # drawing
    dw = Drawable(width, height; fname)
    testpattern1(dw, width, height)
    close(dw)
    return true
end


# test recorder painting
function main3()
    println("main3")
    width = 800
    height = 600
    fname = plotpath("pkcairo3.pdf")
    recwidth = 400
    recheight = 300
    
    # drawing
    rec = RecorderDrawable(recwidth, recheight)
    testpattern1(rec, recwidth, recheight)
    dw = Drawable(width, height; fname)
    rect(dw, Point(0,0), Point(width, height); fillcolor = Color(1,0.8,0.9))
    paint(dw, rec)
    paint(dw, rec, Point(350,250), 0.4)
    close(rec)
    close(dw)
    return true
end

# test recorder save
function main4()
    println("main4")
    width = 800
    height = 600
    fname = plotpath("pkcairo4.pdf")
    
    # drawing
    rec = RecorderDrawable(width, height)
    testpattern1(rec, width, height)
    save(rec, fname)
    close(rec)
    return true
end


# draw using cairo
function main5()
    println("main5")
    d = Drawable(800, 600)
    rect(d, Point(0,0), Point(800, 600); fillcolor = Color(:red))
    line(d, Point(10, 20), Point(800, 450);
         linestyle = LineStyle(Color(:blue), 5))
    line(d, Point(10, 500), Point(600, 50);
         linestyle = LineStyle(Color(:green), 5))
    save(d, plotpath("test_cairo5.png"))
    return true
end


function main6()
    println("main6")
    d = Drawable(800, 600) 
    rect(d, Point(300,20), Point(200, 100); fillcolor = Color(1,0.8,0.8))
    text(d, Point(300,120), 50, Color(:black),
         "Hellogello"; horizontal = "left", vertical="bottom")
    save(d, plotpath("test_cairo6.pdf"))
    return true
end

# beziers
function main7()
    println("main7")
    d = Drawable(800, 600)
    rect(d, Point(0,0), Point(800, 600); fillcolor = Color(:white))
    bezier = Bezier(Point(100,100), Point(600,200), pi/6, pi/6, 0.3)
    curve(d, bezier; linestyle = LineStyle( Color(:black), 2))

    for i=0:0.1:0.5
        p = point(bezier, i)
        circle(d, p, 10; fillcolor = Color(:red))
    end
    save(d, plotpath("test_cairo7.pdf"))
    return true
end
