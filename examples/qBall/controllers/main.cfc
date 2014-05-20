/**
 * I am the main controller.
 * @accessors true
 */
component {

    property question;

    public function init(fw) {
        variables.fw = fw;
    }

    public function default(rc) {
        rc.questions = variables.question.list(perpage=5);
    }

}
