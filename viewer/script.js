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

let simulation
let timePoints

let arrow
let link
let package
let channel
let label

// map node id to node struct
// used to store the positions and velocities of nodes
let globalNodes = new Map()

// svg setup
const svg = d3.select("svg");
let width;
let height;
const defs = svg.append("defs");

const controls = document.getElementById("controls");

function loadSvgSize() {
    const svgBoundingRect = document.getElementById("graph").getBoundingClientRect();
    width = svgBoundingRect.width;
    height = svgBoundingRect.height;
    console.log(`SVG dimensions are: ${width}, ${height}`);
}

const fullscreenButton = document.getElementById("fullscreenButton");
fullscreenButton.addEventListener("click", _ => {
    if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen();
    } else {
        document.exitFullscreen();
    }
});

document.addEventListener('fullscreenchange', () => {
    // Wait a little until the svg has adjusted to the new size.
    // This is sometimes a problem with iframes.
    setTimeout(() => {
        loadSvgSize();
        simulation.force("center", d3.forceCenter(width / 2, height / 2));
        // Nudge everything to make things move into place.
        if (simulation.alpha() < 0.2) {
            simulation.alpha(0.2).restart();
        }
    }, 50);
});

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

    function clampX(x) {
        return Math.max(20, Math.min(width - 20, x));
    }
    function clampY(y) {
        return Math.max(20, Math.min(height - 20, y));
    }

    // update positions
    simulation.on("tick", () => {
        link
            .attr("x1", d => clampX(d.source.x))
            .attr("y1", d => clampY(d.source.y))
            .attr("x2", d => clampX(d.target.x))
            .attr("y2", d => clampY(d.target.y));
        package
            .attr("cx", d => clampX(d.x))
            .attr("cy", d => clampY(d.y));
        channel
            .attr("cx", d => clampX(d.x))
            .attr("cy", d => clampY(d.y));
        label
            .attr("x", d => clampX(d.x))
            .attr("y", d => clampY(d.y - 10));
    });
}

function clearSvg() {
    arrow.remove()
    link.remove()
    package.remove()
    channel.remove()
    label.remove()
}

function setupControls() {
    for (let idx = timePoints.length - 1; idx >= 0; --idx) {
        const date = new Date(timePoints[idx].timestamp * 1000);

        const timePointDiv = document.createElement("div");
        controls.append(timePointDiv);
        timePointDiv.className = "timePointDiv";

        if (timePoints[idx].timestamp >= 1671389768 && timePoints[idx].timestamp < 1693939067) {
            timePointDiv.classList.add("badCommit");
        }

        const timePointInput = document.createElement("input");
        timePointDiv.append(timePointInput);
        timePointInput.type = "radio";
        timePointInput.name = "commit";
        timePointInput.value = idx;
        timePointInput.id = `commit-${idx}`;
        timePointInput.addEventListener("change", e => updateSimulation(e.target.value));

        // timePointDiv.dataset["idx"] = timePoints.length - 1 - idx;

        let timePointLabel = document.createElement("label");
        timePointDiv.append(timePointLabel);
        timePointLabel.innerHTML = `${date.toLocaleString()}, <a target="_blank" href="https://codeberg.org/forgejo/forgejo/commit/${timePoints[idx].commit}">${timePoints[idx].commit.substring(0, 7)}</a>`;
        timePointLabel.htmlFor = `commit-${idx}`;

        if (idx === timePoints.length - 1) {
            timePointInput.checked = true;
        }
    }
}

function initSimulation(data) {
    loadSvgSize();
    timePoints = data
    let timePoint = structuredClone(timePoints[timePoints.length - 1])
    globalNodes = timePoint.packages.concat(timePoint.channels);

    setupControls()

    // simulation setup
    simulation = d3.forceSimulation(globalNodes)
        .force("link", d3.forceLink(timePoint.links).id(d => d.id))
        .force("charge", d3.forceManyBody().strength(-400))
        .force("center", d3.forceCenter(width / 2, height / 2))
        .force("collision", d3.forceCollide().radius(10))
        .alphaMin(0.001);

    populateSvg(timePoint)
}

function updateSimulation(idx) {
    console.log(`changing to idx ${idx}`);
    let timePoint = structuredClone(timePoints[idx])

    var newNodes = timePoint.packages.concat(timePoint.channels);
    simulation.nodes(newNodes)
    simulation.force("link", d3.forceLink(timePoint.links).id(d => d.id))

    // load positions from old state
    for (const newNodeIdx in newNodes) {
        let found = false;
        for (const nodeIdx in globalNodes) {
            if (globalNodes[nodeIdx].id === newNodes[newNodeIdx].id) {
                newNodes[newNodeIdx].x = globalNodes[nodeIdx].x;
                newNodes[newNodeIdx].y = globalNodes[nodeIdx].y;
                newNodes[newNodeIdx].vx = globalNodes[nodeIdx].vx;
                newNodes[newNodeIdx].vy = globalNodes[nodeIdx].vy;
                found = true;
                break;
            }
        }
        if (!found) {
            // console.log(`new ${newNodes[newNodeIdx].id}`);
            newNodes[newNodeIdx].x = width / 2;
            newNodes[newNodeIdx].y = height / 2;
        }
    }
    // update globalNodes
    globalNodes = newNodes

    clearSvg()
    populateSvg(timePoint)

    if (simulation.alpha() < 0.2) {
        simulation.alpha(0.2).restart();
    }
}

window.addEventListener("load", () => {
    fetch("forgejo_data.json").
        then(response => response.json()).
        then(data => {
            return data.map((dataPoint) => ({
                "commit": dataPoint.commit,
                "timestamp": dataPoint.timestamp,
                "packages": dataPoint.packages.map((val) => ({
                    "id": val.replace("forgejo.org/", "").replace("code.gitea.io/gitea/", "")
                })),
                "channels": dataPoint.channels.map((val) => ({
                    "id": val
                })),
                "links": dataPoint.notifies.map((val) => ({
                    "source": val[0].replace("forgejo.org/", "").replace("code.gitea.io/gitea/", ""),
                    "target": val[1].replace("forgejo.org/", "").replace("code.gitea.io/gitea/", "")
                })),
            })
            );
        }).
        then(data => initSimulation(data)).
        catch(error => console.error(error))
});
