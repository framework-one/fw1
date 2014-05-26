component persistent="true" accessors="true" {

    property name="id" generator="native" ormtype="integer" fieldtype="id";
    property name="text" ormtype="text";
    property name="selectedanswer" ormtype="boolean";
    property name="created" ormtype="timestamp";
    property name="edited" ormtype="timestamp";

    // Relationships
    property name="user" fieldType="many-to-one" cfc="user"
            fkcolumn="useridfk";

    //used for votes, hate the name
    property name="approvers" fieldType="many-to-many" cfc="user"
            linktable="approvedanswers_user" fkcolumn="answeridfk"
            inversejoincolumn="useridfk" lazy="extra"
            singularname="approver";

    property name="disapprovers" fieldType="many-to-many" cfc="user"
            linktable="disapprovedanswers_user" fkcolumn="answeridfk"
            inversejoincolumn="useridfk" lazy="extra"
            singularname="disapprover";


    public function getSelectedAnswer() {
        if(isNull(variables.selectedanswer) || !isBoolean(variables.selectedanswer)) return false;
        else return variables.selectedanswer;
    }

}
