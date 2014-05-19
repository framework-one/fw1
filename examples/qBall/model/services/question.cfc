/**
 * I am the question service.
 */
component {

    public any function getQuestion(numeric questionid) {
        return entityLoadByPk("question", arguments.questionid);
    }

    public any function list(numeric start=1, numeric perpage=10) {
        var result = {};
        var hql = "from question order by created desc";
        var result.data = ormExecuteQuery(hql, false, {
            maxResults=arguments.perpage,
            offset=arguments.start-1
        });
        var totalhql = "select count(id) as total from question";
        var result.count = ormExecuteQuery(totalhql, true);

        return result;
    }

    public any function post(string title, string text, any user) {
        transaction {
            var thisUser = entityLoadByPk("user", user);
            var q = entityNew("question");
            q.setTitle(arguments.title);
            q.setText(arguments.text);
            q.setCreated(Now());
            q.setUser(thisUser);
            entitySave(q);
            transactionCommit();
        }
        return q;
    }

    public void function postAnswer(any question, string answer, any user) {
        transaction {
            var aUser =  entityLoadByPk("user", arguments.user);
            var answerOb = entityNew("answer");
            answerOb.setText(arguments.answer);
            answerOb.setUser(aUser);
            answerOb.setSelectedAnswer(false);
            entitySave(answerOb);
            question.addAnswer(answerOb);
            entitySave(question);
            transactionCommit();
        }
    }

    public void function selectAnswer(any question, numeric answerid) {
        //loop over answers, mark ALL as NOT the answer, except the chosen one
        var thisQuestion = entityLoadByPk("question", arguments.question);
        transaction {

            var answers = thisQuestion.getAnswers();
            for(var i=1; i <= arrayLen(answers); i++) {
                if(answers[i].getId() != arguments.answerid) answers[i].setSelectedAnswer(false);
                else answers[i].setSelectedAnswer(true);
                entitySave(answers[i]);
            }
        }
    }

    public void function voteAnswerDown(any question, numeric answerid, any user) {
        //First, if we exist in the list of folks who voted up, kill me
        transaction {
            var thisUser = entityLoadByPk("user", arguments.user);
            var answer = entityLoadByPk("answer", arguments.answerid);
            answer.removeApprover(thisUser);
            if(!answer.hasDisapprover(thisUser)) answer.addDisapprover(thisUser);
            entitySave(answer);
        }
    }

    public void function voteAnswerUp(any question, numeric answerid, any user) {
        //First, if we exist in the list of folks who voted up, kill me
        transaction {
            var thisUser = entityLoadByPk("user", arguments.user);
            var answer = entityLoadByPk("answer", arguments.answerid);
            answer.removeDisapprover(thisUser);
            if(!answer.hasApprover(thisUser)) answer.addApprover(thisUser);
            entitySave(answer);
            transactionCommit();
        }
    }

}
