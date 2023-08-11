using Dates
using URIs

"""
    {{blogposts}}
Plug in the list of blog posts contained in the `/blog/` folder.
"""
@delay function hfun_blogposts()
    today = Dates.today()
    curyear = year(today)
    curmonth = month(today)
    curday = day(today)

    list = readdir("blog")
    filter!(f -> endswith(f, ".md"), list)
    sorter(p) = begin
        ps = splitext(p)[1]
        url = "/blog/$ps/"
        surl = strip(url, '/')
        pubdate = pagevar(surl, :published)
        if isnothing(pubdate)
            return Date(Dates.unix2datetime(stat(surl * ".md").ctime))
        end
        return Date(pubdate, dateformat"d U Y")
    end
    sort!(list, by=sorter, rev=true)

    io = IOBuffer()
    write(io, """<ul class="blog-posts">""")
    for (i, post) in enumerate(list)
        if post == "index.md"
            continue
        end
        ps = splitext(post)[1]
        write(io, "<li><span><i>")
        url = "/blog/$ps/"
        surl = strip(url, '/')
        title = pagevar(surl, :title)
        pubdate = pagevar(surl, :published)
        if isnothing(pubdate)
            date = "$curyear-$curmonth-$curday"
        else
            date = Date(pubdate, dateformat"d U Y")
        end
        write(io, """$date </i></span><a href="$url">$title</a>""")
    end
    write(io, "</ul>")
    return String(take!(io))
end

function hfun_bar(vname)
    val = Meta.parse(vname[1])
    return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
    var = vname[1]
    return pagevar("index", var)
end

function lx_baz(com, _)
    # keep this first line
    brace_content = Franklin.content(com.braces[1]) # input string
    # do whatever you want here
    return uppercase(brace_content)
end



"""
    {{check_commonplace_links}}
Fix links in notes contained in the `/commonplace/` folder.
"""
@delay function hfun_check_commonplace_links()
    list = readdir("commonplace")
    filter!(f -> endswith(f, ".html"), list)

    for note in list
        src_lines = readlines(string("commonplace/" * note))
        mod_lines = String[]

        for line in src_lines
            if occursin(r"\<a href\=\"(.*?)\"", line)
                m = match(r"\<a href\=\"(.*?)\"", line)
                url = URI(m.captures[1])

                filename, ext = splitext(basename(url.path))

                # here we consider the ".html" extension and replace it with empty string
                if ext == ".html"
                    new_url = "../" * filename
                    line = replace(line, m.match => "<a href=\"" * new_url * "\"")
                end
            end

            push!(mod_lines, line)
        end

        # Write updated lines back to the file
        open("commonplace/" * note, "w") do f
            write(f, join(mod_lines, "\n"))
        end
    end
end
