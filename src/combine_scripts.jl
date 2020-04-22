function io_buffer_header(width::Int=900,height::Int=600)
  header = """
  <link rel="stylesheet" type="text/css" href="//fonts.googleapis.com/css?family=Arvo" />
  <style>


  #h1{
    width:100%;
    font-size:15px;
    display: inline-block;
    padding: 20px;
  }

  .links line {
    stroke: #999;
    stroke-opacity: 0.6;
  }
  .nodes circle {
    stroke: #fff;
    stroke-width: 1.5px;
  }
  #GraphPlayground {
    z-index: -1;
    width: 100%;
    height:100%;
  }

  .interfaceBox {

    position: absolute;
    z-index: 1;
    top: 100px;
    right: 40px;
    
    width: 150px;
    height: 400px;
    border: 3px solid #dbdbdb;  
    opacity: .8;
    background-color: #dbdbdbAA;
    border-radius: 10px;
    box-shadow: rgba(0, 0, 0, 0.4) -3px 3px 5px

    text-align:center;
    font-family:Arvo;
    }

  .svg-container {
    display: inline-block;
    position: relative;
    width: 100%;
    padding-bottom: 100%; /* aspect ratio */
    vertical-align: top;
    overflow: hidden;
    }

  .svg-content-responsive {
    display: block;
    position: absolute;
    top: 10px;
    left: 0;
   }

  }
  </style>
  <script> 

  var svg = d3.select("#GraphPlayground")
  .append("div")
   // Container class to make it responsive.
     .classed("svg-container", true) 
     .append("svg")
     // Responsive SVG needs these 2 attributes and no width and height attr.
     .attr("preserveAspectRatio", "xMinYMin meet")
     .attr("viewBox", "0 0 600 400") //TODO: understand viewBox 
     // Class to make it responsive.
     .classed("svg-content-responsive", true)
       
    height = +svg.attr("height");
    width  = +svg.attr("width");
  const g = svg.append("g");
  //create somewhere to put the force directed graph
  """
  f = IOBuffer();
  write(f,header)
  return String(take!(f))
end

function io_buffer_graph(A::SparseMatrixCSC)
  n = size(A,1)
  @assert size(A,2) == n
  ei,ej = findnz(A)[1:2]
  f = IOBuffer();
  write(f, "var nodes_data = [")
  for i=1:n
      write(f, "  {\"name\": \"$i\"},\n")
  end
  write(f, "]\n")
  write(f, "var links_data = [")
  for nzi = 1:length(ei)
      i,j = ei[nzi], ej[nzi]
      write(f, "  {\"source\": \"$i\", \"target\": \"$j\"},\n")
  end
  write(f, "]\n")
  return String(take!(f))
end

function io_buffer_footer()
  footer = """
  //set up the simulation
  //nodes only for now
  var simulation = d3.forceSimulation()
            //add nodes
            .nodes(nodes_data);
  //add forces
  //we're going to add a charge to each node
  //also going to add a centering force
  simulation
      .force("charge_force", d3.forceManyBody())
      .force("center_force", d3.forceCenter(width / 2, height / 2));
  //Time for the links
  //Add a links force to the simulation
  //Specify links  in d3.forceLink argument
  //add tick instructions:
  simulation.on("tick", tickActions );
  //Create the link force
  //We need the id accessor to use named sources and targets
  var link_force =  d3.forceLink(links_data)
                          .id(function(d) { return d.name; })
  simulation.force("links",link_force)
  //draw lines for the links
  var link = svg.append("g")
        .attr("class", "links")
      .selectAll("line")
      .data(links_data)
      .enter().append("line")
        .attr("stroke-width", 2);
  //draw circles for the nodes
  var node = svg.append("g")
          .attr("class", "nodes")
          .selectAll("circle")
          .data(nodes_data)
          .enter()
          .append("circle")
          .attr("r", 5)
          .attr("fill", "red")
          .call(d3.drag()
                .on("start", dragstarted)
                .on("drag", dragged)
                .on("end", dragended))
      .on("mouseover", handleMouseOver)
      .on("mouseout", handleMouseOut)
      .on("onclick",savecoords);
   svg.call(d3.zoom()
    .extent([[0, 0], [width, height]])
    .scaleExtent([1, 8])
    .on("zoom", zoomed));

    // Add a tooltip div. Here I define the general feature of the tooltip: stuff that do not depend on the data point.
    // Its opacity is set to 0: we don't see it by default.
    var tooltip = d3.select("#GraphPlayground")
      .append("div")
      .style("opacity", 0)
      .attr("class", "tooltip")
      .style("background-color", "white")
      .style("position", "absolute")
      .style("top", "0px")
      .style("right","40px");

    var coordinateBox = d3.select("#GraphPlayground")
      .append("div")
      .attr("class", "tooltip")
      .style("opacity", 1)
      .style("position", "absolute")
      .style("top", "0px")
      .style("right","150px")
      .text("Coordinates: "); 
  
  function zoomed() {
    link.attr("transform",d3.event.transform);
    node.attr("transform", d3.event.transform);
  }
  
  function savecoords() {
    // This still needs to be fixed. The goal is to store the coordinates of all nodes into positions.
    var positions = node.nodes().forEach(function(d) { return [d.x, d.y]; });
    var positions = node.nodes()//, typeof node.data]
    Blink.msg("press", positions);
  }
  function tickActions() {
      //update circle positions each tick of the simulation
      node
          .attr("cx", function(d) { return d.x; })
          .attr("cy", function(d) { return d.y; });
      //update link positions
      //simply tells one end of the line to follow one node around
      //and the other end of the line to follow the other node around
      link
          .attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });
    }
  function dragstarted(d) {
    if (!d3.event.active) simulation.alphaTarget(0.3).restart();
    d.fx = d.x;
    d.fy = d.y;
  }
  function dragged(d) {
    d.fx = d3.event.x;
    d.fy = d3.event.y;
    tooltip.html("(" + d.x.toFixed(2) + ", " + d.y.toFixed(2) + ")");
  }
  function dragended(d) {
    if (!d3.event.active) simulation.alphaTarget(0);
    d.fx = null;
    d.fy = null;
  }
  // Create Event Handlers for mouse
    function handleMouseOver(d) {  // Add interactivity

        // Use D3 to select element, change color and size
        d3.select(this).transition().attr("fill", "orange").attr("r", 10);
        tooltip.html("(" + d.x.toFixed(2) + ", " + d.y.toFixed(2) + ")")
               .style("opacity",1);
    	//d3.select(this).transition().attr("r", 10);
      //d.transition().attr("r",10);
    }

    function handleMouseOut(d) {
        // Use D3 to select element, change color back to normal
        d3.select(this).transition().attr("fill", "red").attr("r", 5);
        tooltip.style("opacity",0);
    	//d3.select(this).transition().attr("r", 5);
    	//d.transition().attr("r",5);
      }
    </script>
    <div id="GraphPlayground">
         <div class="interfaceBox">
	      <h1>GraphPlayground.jl</h1>
	      <button onclick='savecoords()'>Get Coordinates</button>
         </div>
    </div>
    

  """
  f = IOBuffer();
  write(f, footer)
  return String(take!(f))
end


#Example
function run_example()
  A = sprandn(10,10,0.2)
  w = Window()
  opentools(w)
  loadjs!(w,"https://d3js.org/d3.v4.min.js")
  loadjs!(w,"https://d3js.org/d3-zoom.v1.min.js")
  
  header = io_buffer_header()
  graph = io_buffer_graph(A)
  # other_str = io_buffer_other_functionality(A)
  footer = io_buffer_footer()
  # body!(w,header*graph*other_str*footer)

  open("test.html","w") do f
    print(f,header*graph*footer)
  end



  body!(w,header*graph*footer)


  #TODO: global variable may be fragile, had type issues
  positions = [Array{Any,1}(undef,0)]


  @js w x = 5
  handle(w, "press") do args...
     x = args[1]
     # Increment x
     #@js_ w (x = $x + 1)  # Note the _asynchronous_ call.
     #  println("New value: $x")
     #  push!(positions,args[1])
     positions[1] = args[1]
     locations = [(x["__data__"]["x"],x["__data__"]["y"]) for x in positions[1]]
     println(locations)
  end
end