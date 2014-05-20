component accessors="true" {

    property question;

    function init(fw) {
        variables.fw = fw;
    }

    //Used by a few methods to validate/load a question
    private function loadQuestion(rc) {
        if(!structKeyExists(rc, "questionid") || !isNumeric(rc.questionid) ||
                            rc.questionid <= 0) {
            variables.fw.redirect("main.default");
        }
    }

    public function list(rc) {

        rc.result = variables.question.list();

        /*if (!structKeyExists(session, "isLoggedIn")) {
            rc.errors = "You are not logged in";
            variables.fw.redirect("main.default", "errors");
        }*/

        if(structKeyExists(rc, "start") && (!isNumeric(rc.start) ||
                            rc.start <= 0 || round(rc.start) != rc.start)) {

            rc.start = true;
        }
    }


    function post(rc) {
        rc.errors = [];
        if(!len(trim(rc.title))) {
            arrayAppend(rc.errors, "You must include a title for your question.");
        }

        if(!len(trim(rc.text))) {
            arrayAppend(rc.errors, "You must include text for your question.");
        }

        if(arrayLen(rc.errors)) {
            variables.fw.redirect("question.new", "title,text,errors");
        }

        rc.data = variables.question.post(rc.title, rc.text, session.auth.userid);
        //Right now we assume the post just worked
        rc.questionid = rc.data.getId();
        variables.fw.redirect("main.default");
    }

    function postAnswer(rc) {

        loadQuestion(rc);
        rc.question = variables.question.getQuestion(rc.questionid);

        rc.answer = trim(htmlEditFormat(rc.answer));

        variables.question.postAnswer(rc.question, rc.answer,
                                        session.auth.userid);

        //Right now we assume the post just worked
        rc.questionid = rc.question.getId();
        variables.fw.redirect("question.view","none","questionid");
    }

    function selectAnswer(rc) {
        loadQuestion(rc);


        variables.question.selectAnswer(rc.questionid, rc.answerid);
        variables.fw.redirect("question.view","none","questionid");
    }

    function view(rc) {
        loadQuestion(rc);
        rc.question = variables.question.getQuestion(rc.questionid);
    }

    function voteAnswerDown(rc) {
        loadQuestion(rc);
        rc.question = variables.question.getQuestion(rc.questionid);
        variables.question.voteAnswerDown(url.questionid, url.answerid, session.auth.userid);
        rc.questionid = rc.question.getId();
        variables.fw.redirect("question.view","none","questionid");
    }

    function voteAnswerUp(rc) {
        loadQuestion(rc);
        rc.question = variables.question.getQuestion(rc.questionid);
        variables.question.voteAnswerUp(url.questionid, url.answerid, session.auth.userid);
        rc.questionid = rc.question.getId();
        variables.fw.redirect("question.view","none","questionid");
    }

}
