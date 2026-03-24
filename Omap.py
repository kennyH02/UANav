# imports
import osmnx as ox
import networkx as nx
import matplotlib.pyplot as mpl
import json as json
# location
place = "University at Albany, New York, USA"
# terminal message
print("Downloading street network data for {}...".format(place))
# download openstreetmap data
G = ox.graph_from_place(place, network_type="walk")
# terminal mesage
print("download gragh to Json")

nodes=[]
edges=[]
# loops through all N / E, takes lat and long from OSM
for node, data in G.nodes(data=True):
    nodes.append({
        "id": str(node),
        "latitue": data["y"],
        "longitude": data["x"],
        "type": "outside_campus"
    })
for s, t, data in G.edges(data=True):
        edges.append({
            "source": str(s),
            "target": str(t),
            "length": data.get("length",1),
            "type": "outside_campus"
    })

outside_campus = {
            "nodes": nodes,
            "edges": edges,
        }
# stores to JSON
with open("outside_campus.json", "w") as f:
            json.dump(outside_campus, f, indent=1)
print("Campus map was saved to outside_campus.json")


with open("outside_campus.json") as f:
        data = json.load(f)
# grapgh
latitue ={}
longitude ={}

for node in data["nodes"]:
    latitue[node["id"]] = node["latitue"]
    longitude[node["id"]] = node["longitude"]

for edge in data["edges"]:
    s = edge["source"]
    t = edge["target"]
    x = [longitude[s], longitude[t]]
    y = [latitue[s], latitue[t]]

    mpl.plot(x,y, color = "purple", linewidth =0.5)

mpl.title("UANav Nodes and Edges")
mpl.xlabel("longitude")
mpl.ylabel("latitue")
mpl.show()