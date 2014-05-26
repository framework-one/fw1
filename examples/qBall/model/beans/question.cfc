component persistent="true" accessors="true" {

    property name="id" generator="native" ormtype="integer" fieldtype="id";
    property name="title" ormtype="string" length="255";
    property name="text" ormtype="text";
    property name="created" ormtype="timestamp";
    property name="edited" ormtype="timestamp";

    // Relationships
    property name="user" fieldType="many-to-one" cfc="user"
            fkcolumn="useridfk";

    property name="answers" fieldType="many-to-many" cfc="answer"
            linktable="question_answer" fkcolumn="questionidfk"
            inversejoincolumn="answeridfk" lazy="true"
            singularname="answer";

    public function getAnswered() {
        var hql = "
            select a.id
            from question q join q.answers a
            where a.selectedanswer = 1 and q.id = ?
        ";
        var r = ormExecuteQuery(hql, [variables.id]);
        return arrayLen(r) is 1;
    }
}
