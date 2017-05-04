# Create ModelBuilder (with two-dimensions and 2 DOF/node)
model BasicBuilder -ndm 2 -ndf 2
wipe

# Create nodes
# ------------

# Create nodes & add to Domain - command: node nodeId xCrd yCrd
node 1   0.0  0.0
node 2 144.0  0.0
node 3 168.0  0.0
node 4  72.0 96.0

# Set the boundary conditions - command: fix nodeID xResrnt? yRestrnt?
fix 1 1 1 
fix 2 1 1
fix 3 1 1

# Define materials for truss elements
# -----------------------------------

set E 3000
# Create Elastic material prototype - command: uniaxialMaterial Elastic matID E
uniaxialMaterial Elastic 1 $E


# Define elements
# ---------------

# Create truss elements - command: element truss trussID node1 node2 A matID
set eleType truss
element $eleType 1 1 4 10.0 1
element $eleType 2 2 4 5.0 1
element $eleType 3 3 4 1

# Define loads
# ------------

# Create a Plain load pattern with a linear TimeSeries
pattern Plain 1 "Linear" {    
    # Create the nodal load - command: load nodeID xForce yForce
    load 4 100 -50
}

# ------------------------------
# End of model generation
# ------------------------------


# ------------------------------
# Start of analysis generation
# ------------------------------

# Create the system of equation, a SPD using a band storage scheme
system BandSPD

# Create the DOF numberer, the reverse Cuthill-McKee algorithm
numberer RCM

# Create the constraint handler, a Plain handler is used as homo constraints
constraints Plain

# Create the integration scheme, the LoadControl scheme using steps of 1.0
integrator LoadControl 1.0

# Create the solution algorithm, a Linear algorithm is created
algorithm Linear

# create the analysis object 
analysis Static 

analyze 10

# ------------------------------
# End of analysis generation
# ------------------------------

set maxU [nodeDisp 4 2]
puts $maxU
