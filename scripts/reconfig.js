var config = rs.conf();
config.members[0].host = "34.48.123.190:27017";
config.members[1].host = "34.85.131.72:27017";
config.members[2].host = "34.21.32.8:27017";
rs.reconfig(config, {force: true});
