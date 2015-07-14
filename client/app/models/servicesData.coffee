module.exports =#class servicesData extends Backbone.Model
  s1:
    displayName: "Moodle"
    clientIcon: "fa fa-file-o"
    clientServiceUrl: "moodle"
    serverServiceUrl: "moodle/login/index.php"
  s2:
    displayName: "webAurion"
    clientIcon: "fa fa-calendar"
    clientServiceUrl: "webAurion"
    serverServiceUrl: "webAurion/j_spring_cas_security_check"
  s3:
    displayName: "Webmail"
    clientIcon: "fa fa-calendar"
    clientServiceUrl: "horde"
    serverServiceUrl: "horde/login.php"
  s4:
    displayName: "Trombinoscope"
    clientIcon: "fa fa-users"
    clientServiceUrl: "trombino"
    serverServiceUrl: "trombino/index.php"
  s5:
    displayName: "Evaluation des enseignements"
    clientIcon: "fa fa-thumbs-o-up"
    clientServiceUrl: "eval"
    serverServiceUrl: "Eval/index.php"
