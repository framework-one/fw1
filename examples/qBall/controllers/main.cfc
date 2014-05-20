/**
 * I am the main controller.
 */
component accessors="true" {

    property question;

    public function init(fw) {
        variables.fw = fw;
    }

    public function default(rc) {
        rc.questions = variables.question.list(perpage=5);
    }

}
