// slightly transparent
const hideLineColor = "#99999922";
const defaultLineColor = "#999999ff";
const highlightLineColor = "#999999ff";

// fully transparent
const hideArrowColor = "#ffffff00";
const defaultArrowColor = "#999999ff";
const highlightArrowColor = "#999999ff";

const hidePackageColor = "#ffebddff";
const defaultPackageColor = "#ff6600ff";
const highlightPackageColor = "#ff6600ff";

const hideChannelColor = "#e1eff9ff";
const defaultChannelColor = "#2185d0ff";
const highlightChannelColor = "#2185d0ff";

const hideTextColor = "#00000022";
const defaultTextColor = "#000000ff";
const highlightTextColor = "#000000ff";

var simulation
var timePoints

var arrow
var link
var package
var channel
var label

// svg setup
const svg = d3.select("svg");
const width = Number(svg.attr("width"));
const height = Number(svg.attr("height"));
const defs = svg.append("defs");

function populateSvg(data) {
    // arrowhead marker for lines
    // Create one for each link there is.
    // This allows us to set the color individually.
    arrow = defs.selectAll("marker")
        .data(data.links)
        .join("marker")
        .attr("id", (_d, i) => `arrowhead-${i}`)
        .attr("viewBox", "0 -5 10 10")
        .attr("refX", 15)
        .attr("refY", 0)
        .attr("markerWidth", 8)
        .attr("markerHeight", 8)
        .attr("orient", "auto")
        .append("path")
        .attr("d", "M0,-5L10,0L0,5")
        .attr("fill", defaultArrowColor);
    // edges
    link = svg.append("g")
        .attr("stroke", defaultLineColor)
        .style("color", defaultArrowColor)
        .attr("stroke-opacity", 0.6)
        .selectAll("line")
        .data(data.links)
        .join("line")
        .attr("stroke-width", 1.5)
        .attr("marker-end", (_d, i) => `url(#arrowhead-${i})`);
    // nodes
    package = svg.append("g")
        .attr("stroke", "#fff")
        .attr("stroke-width", 1.5)
        .selectAll("circle")
        .data(data.packages)
        .join("circle")
        .attr("r", 10)
        .attr("fill", defaultPackageColor);
    channel = svg.append("g")
        .attr("stroke", "#fff")
        .attr("stroke-width", 1.5)
        .selectAll("circle")
        .data(data.channels)
        .join("circle")
        .attr("r", 10)
        .attr("fill", defaultChannelColor);
    // node labels
    label = svg.append("g")
        .selectAll("text")
        .data(data.packages.concat(data.channels))
        .join("text")
        .text(d => d.id)
        .attr("font-size", 10)
        .attr("fill", defaultTextColor)
        .attr("text-anchor", "middle")
        .attr("dy", -10);

    // Do this after creating the simulation.
    // Otherwise the id wouldn't have been populated yet.
    let linkedLookup = {};
    data.links.forEach(link => {
        linkedLookup[`${link.source.id},${link.target.id}`] = true;
        linkedLookup[`${link.target.id},${link.source.id}`] = true;
    });
    function isLinked(nodeA, nodeB) {
        return nodeA.id === nodeB.id || linkedLookup[`${nodeA.id},${nodeB.id}`];
    }

    function nodeMouseOver(_event, node) {
        package.attr("fill", other => (isLinked(node, other) ? highlightPackageColor : hidePackageColor));
        channel.attr("fill", other => (isLinked(node, other) ? highlightChannelColor : hideChannelColor));

        link.each(function(l, i) {
            const connected = l.source.id === node.id || l.target.id === node.id;
            const lineColor = connected ? highlightLineColor : hideLineColor;
            const arrowColor = connected ? highlightArrowColor : hideArrowColor;
            // update line
            d3.select(this).attr("stroke", lineColor);
            // update arrow
            d3.select(`#arrowhead-${i} path`).attr("fill", arrowColor);
        });

        label.attr("fill", other => (isLinked(node, other) ? highlightTextColor : hideTextColor));
    }
    function nodeMouseOut(_event, _node) {
        // reset
        package.attr("fill", defaultPackageColor);
        channel.attr("fill", defaultChannelColor);
        link.attr("stroke", defaultLineColor);
        arrow.attr("fill", defaultArrowColor);
        label.attr("fill", defaultTextColor);
    }
    package.on("mouseover", nodeMouseOver)
        .on("mouseout", nodeMouseOut);
    channel.on("mouseover", nodeMouseOver)
        .on("mouseout", nodeMouseOut);

    // update positions
    simulation.on("tick", () => {
        link
            .attr("x1", d => d.source.x)
            .attr("y1", d => d.source.y)
            .attr("x2", d => d.target.x)
            .attr("y2", d => d.target.y);
        package
            .attr("cx", d => d.x)
            .attr("cy", d => d.y);
        channel
            .attr("cx", d => d.x)
            .attr("cy", d => d.y);
        label
            .attr("x", d => d.x)
            .attr("y", d => d.y - 10);
    });
}

function clearSvg() {
    arrow.remove()
    link.remove()
    package.remove()
    channel.remove()
    label.remove()
}

function initSimulation(data) {
    timePoints = data
    // simulation setup
    simulation = d3.forceSimulation(timePoints[0].packages.concat(timePoints[0].channels))
        .force("link", d3.forceLink(timePoints[0].links).id(d => d.id))
        .force("charge", d3.forceManyBody().strength(-500))
        .force("center", d3.forceCenter(width / 2, height / 2));

    populateSvg(timePoints[0])
}

function updateSimulation(idx) {
    simulation.nodes(timePoints[idx].packages.concat(timePoints[idx].channels))
    simulation.force("link", d3.forceLink(timePoints[idx].links).id(d => d.id))
    clearSvg()
    populateSvg(timePoints[idx])

    if (simulation.alpha() < 0.05) {
        simulation.alphaTarget(0.2).restart();
    }
}

fetch("forgejo_data.json").
    then(response => response.json()).
    then(data => {
        console.log(data);
        return data.map((dataPoint) => ({
            "commit": dataPoint.commit,
            "timestamp": dataPoint.timestamp,
            "packages": dataPoint.packages.map((val) => ({ "id": val.replace("forgejo.org/", "").replace("code.gitea.io/gitea", "") })),
            "channels": dataPoint.channels.map((val) => ({ "id": val })),
            "links": dataPoint.notifies.map((val) => ({ "source": val[0].replace("forgejo.org/", "").replace("code.gitea.io/gitea", ""), "target": val[1].replace("forgejo.org/", "").replace("code.gitea.io/gitea", "") })),
        })
        );
    }).
    then(data => initSimulation(data)).
    catch(error => console.error(error))
