#INCLUDE "PROTHEUS.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TOPCONN.CH"

/*/
*******************************************************************************
*******************************************************************************
*Programa   ZA1A010  * Autor  Delson                * Data  02.07.2026
*******************************************************************************
*Descricao  Manutencao (MVC) do cadastro de Grupo Financeiro (ZA1).
*           Cabecalho = ZA1 (Filial/Codigo/Descricao).
*           Grade     = Clientes (SA1) vinculados ao grupo atraves do
*                       campo A1_ZGRPFIN.
*           A grade NAO e uma tabela filha real de ZA1 (nao existe FK).
*           Por isso o vinculo Cliente x Grupo nao e persistido pelo
*           FWFormCommit padrao: ele e feito manualmente via RECLOCK na
*           SA1 dentro do commit do model (ver ModelCommit()).
*******************************************************************************
*   DATA   * Programador   *Manutencao efetuada
*******************************************************************************
*           *               *
*******************************************************************************
*******************************************************************************
/*/

//-------------------------------------------------------------------------
// Rotina principal - Browse
//-------------------------------------------------------------------------
User Function ZA1A010()
	Local oBrowse := Nil

	oBrowse := FWFormBrowse():New()
	oBrowse:SetAlias("ZA1")
	oBrowse:SetDescription("Grupos Financeiros")
	oBrowse:Activate()

Return

//-------------------------------------------------------------------------
// ModelDef - Estrutura de dados e regras
//-------------------------------------------------------------------------
Static Function ModelDef()
	Local oModel      := Nil
	Local oStructZA1  := Nil
	Local oStructGrid := Nil

	oStructZA1 := FWFormStruct(1, "ZA1")

	// A grade reaproveita a estrutura da SA1 apenas para herdar tipo,
	// tamanho, "F3" (consulta padrao de cliente) e mascara dos campos.
	// So ficam visiveis codigo/loja/nome; o vinculo com o grupo
	// (A1_ZGRPFIN) fica fora do struct e e tratado manualmente.
	oStructGrid := FWFormStruct(1, "SA1")
	oStructGrid:SetOnlyFields({"A1_FILIAL", "A1_COD", "A1_LOJA", "A1_NOME"})

	oModel := MPFormModel():New("ZA1A010M", /*bPreValidacao*/, /*bPosValidacao*/, {|oModel| ModelCommit(oModel)}, /*bCancelDados*/)
	oModel:AddFields("ZA1MASTER", /*cOwner*/, oStructZA1)
	oModel:AddGrid("SA1DETAIL", "ZA1MASTER", oStructGrid)

	// Relacao "tecnica" apenas para a grade funcionar dentro do model
	// (default de filial para novas linhas). Nao ha FK real com a ZA1.
	oModel:SetRelation("SA1DETAIL", { ;
		{"A1_FILIAL", "FWxFilial('SA1')"} ;
	}, SA1->(IndexKey(1)))

	oModel:GetModel("SA1DETAIL"):SetDescription("Clientes vinculados ao Grupo Financeiro")
	oModel:GetModel("SA1DETAIL"):SetOptional(.T.)

	oModel:SetDescription("Cadastro de Grupo Financeiro")
	oModel:GetModel("ZA1MASTER"):SetDescription("Grupo Financeiro")
	oModel:SetPrimaryKey({})

	// Codigo do grupo nao pode ser alterado depois de incluido
	oStructZA1:SetProperty("ZA1_CODIGO", MODEL_FIELD_WHEN, FWBuildFeature(STRUCT_FEATURE_WHEN, "oModel:GetOperation() != MODEL_OPERATION_UPDATE"))

	oModel:SetActivate({|oModel| ModelActivate(oModel)})
	oModel:SetVldActive({|oModel| ModelValidate(oModel)})

	// Validacao de cada linha da grade (codigo/loja obrigatorios e existentes)
	oModel:GetModel("SA1DETAIL"):SetVldLine({|oModelGrid| GridVldLine(oModelGrid)})

	// Gatilho: ao informar/alterar a loja, busca o nome do cliente na SA1
	oStructGrid:SetProperty("A1_LOJA", MODEL_FIELD_VALID, FWBuildFeature(STRUCT_FEATURE_VALID, "GridTrigNome(oModel)"))

	// Nome e somente leitura - sempre preenchido pelo gatilho acima
	oStructGrid:SetProperty("A1_NOME", MODEL_FIELD_WHEN, FWBuildFeature(STRUCT_FEATURE_WHEN, ".F."))

Return oModel

//-------------------------------------------------------------------------
// ViewDef - Layout visual (cabecalho + grade)
//-------------------------------------------------------------------------
Static Function ViewDef()
	Local oView         := Nil
	Local oModel        := Nil
	Local oStructZA1    := Nil
	Local oStructGrid   := Nil

	oModel := FWLoadModel("ZA1A010")

	oStructZA1  := FWFormStruct(2, "ZA1")
	oStructGrid := FWFormStruct(2, "SA1")
	oStructGrid:SetOnlyFields({"A1_COD", "A1_LOJA", "A1_NOME"})

	oView := FWFormView():New()
	oView:SetModel(oModel)

	oView:AddField("VIEW_ZA1", oStructZA1, "ZA1MASTER")
	oView:CreateHorizontalBox("BOX_MASTER", 30)
	oView:SetOwnerView("VIEW_ZA1", "BOX_MASTER")

	oView:AddGrid("VIEW_SA1", oStructGrid, "SA1DETAIL")
	oView:CreateHorizontalBox("BOX_DETAIL", 70)
	oView:SetOwnerView("VIEW_SA1", "BOX_DETAIL")
	oView:EnableTitleView("VIEW_SA1", "Clientes do Grupo")

Return oView

//-------------------------------------------------------------------------
// MenuDef - Acoes disponiveis
//-------------------------------------------------------------------------
Static Function MenuDef()
	Local aMenu := {}

	aAdd(aMenu, {"Incluir",   "VIEWDEF.ZA1A010", 0, 1, 0, Nil})
	aAdd(aMenu, {"Alterar",   "VIEWDEF.ZA1A010", 0, 2, 0, Nil})
	aAdd(aMenu, {"Excluir",   "VIEWDEF.ZA1A010", 0, 3, 0, Nil})
	aAdd(aMenu, {"Visualizar","VIEWDEF.ZA1A010", 0, 4, 0, Nil})

Return aMenu

//-------------------------------------------------------------------------
// ModelActivate - Ao abrir a tela (Alterar/Excluir/Visualizar), carrega
// na grade os clientes ja vinculados ao grupo (via A1_ZGRPFIN)
//-------------------------------------------------------------------------
Static Function ModelActivate(oModel)
	Local oModelGrid := oModel:GetModel("SA1DETAIL")
	Local cFilCli    := xFilial("SA1")
	Local cCodigo    := oModel:GetValue("ZA1MASTER", "ZA1_CODIGO")
	Local cAliasQry  := Nil
	Local cQuery     := ""

	If oModel:GetOperation() != MODEL_OPERATION_INSERT .And. !Empty(cCodigo)

		cAliasQry := GetNextAlias()

		cQuery := " SELECT A1_COD, A1_LOJA, A1_NOME "
		cQuery += " FROM " + RetSqlName("SA1") + " SA1 "
		cQuery += " WHERE SA1.A1_FILIAL = '" + cFilCli + "' "
		cQuery += "   AND SA1.A1_ZGRPFIN = '" + cCodigo + "' "
		cQuery += "   AND SA1.D_E_L_E_T_ = ' ' "
		cQuery += " ORDER BY A1_COD, A1_LOJA "

		dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQry, .F., .T.)

		While (cAliasQry)->(!Eof())
			oModelGrid:AddLine()
			oModelGrid:SetValue("A1_COD",  (cAliasQry)->A1_COD)
			oModelGrid:SetValue("A1_LOJA", (cAliasQry)->A1_LOJA)
			oModelGrid:SetValue("A1_NOME", (cAliasQry)->A1_NOME)
			(cAliasQry)->(DbSkip())
		End

		(cAliasQry)->(DbCloseArea())
	EndIf

Return .T.

//-------------------------------------------------------------------------
// ModelValidate - Validacoes gerais do model antes do commit
//-------------------------------------------------------------------------
Static Function ModelValidate(oModel)
	Local lValid := .T.

	If Empty(oModel:GetValue("ZA1MASTER", "ZA1_CODIGO"))
		Help(,, "ZA1A010", , "Codigo do grupo financeiro e obrigatorio.", 1, 0)
		lValid := .F.
	ElseIf Empty(oModel:GetValue("ZA1MASTER", "ZA1_DESCRICAO"))
		Help(,, "ZA1A010", , "Descricao do grupo financeiro e obrigatoria.", 1, 0)
		lValid := .F.
	EndIf

Return lValid

//-------------------------------------------------------------------------
// GridVldLine - Validacao de cada linha da grade de clientes
//-------------------------------------------------------------------------
Static Function GridVldLine(oModelGrid)
	Local lValid  := .T.
	Local cCod    := oModelGrid:GetValue("A1_COD")
	Local cLoja   := oModelGrid:GetValue("A1_LOJA")
	Local cFilCli := xFilial("SA1")
	Local nLinha  := oModelGrid:GetLine()
	Local nX      := 0

	If oModelGrid:IsDeleted()
		Return .T.
	EndIf

	If Empty(cCod) .Or. Empty(cLoja)
		Help(,, "ZA1A010", , "Codigo e loja do cliente sao obrigatorios.", 1, 0)
		Return .F.
	EndIf

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
	If !SA1->(MsSeek(cFilCli + cCod + cLoja))
		Help(,, "ZA1A010", , "Cliente/loja nao encontrado no cadastro de clientes.", 1, 0)
		Return .F.
	EndIf

	// Nao permite o mesmo cliente/loja duplicado na grade
	For nX := 1 To oModelGrid:Length()
		If nX != nLinha
			oModelGrid:GoLine(nX)
			If !oModelGrid:IsDeleted() .And. oModelGrid:GetValue("A1_COD") == cCod .And. oModelGrid:GetValue("A1_LOJA") == cLoja
				lValid := .F.
			EndIf
		EndIf
	Next nX
	oModelGrid:GoLine(nLinha)

	If !lValid
		Help(,, "ZA1A010", , "Este cliente ja esta vinculado ao grupo nesta grade.", 1, 0)
	EndIf

Return lValid

//-------------------------------------------------------------------------
// GridTrigNome - Gatilho: ao informar codigo+loja, busca o nome na SA1
//-------------------------------------------------------------------------
Static Function GridTrigNome(oModel)
	Local lRet    := .T.
	Local cCod    := oModel:GetValue("A1_COD")
	Local cLoja   := oModel:GetValue("A1_LOJA")
	Local cFilCli := xFilial("SA1")

	If !Empty(cCod) .And. !Empty(cLoja)
		DbSelectArea("SA1")
		SA1->(DbSetOrder(1)) // A1_FILIAL+A1_COD+A1_LOJA
		If SA1->(MsSeek(cFilCli + cCod + cLoja))
			oModel:SetValue("A1_NOME", SA1->A1_NOME)
		Else
			Help(,, "ZA1A010", , "Cliente/loja nao encontrado no cadastro de clientes.", 1, 0)
			lRet := .F.
		EndIf
	EndIf

Return lRet

//-------------------------------------------------------------------------
// ModelCommit - Grava o cabecalho (ZA1) e sincroniza manualmente o
// vinculo Cliente x Grupo Financeiro (A1_ZGRPFIN) via RECLOCK na SA1
//-------------------------------------------------------------------------
Static Function ModelCommit(oModel)
	Local lRet       := .T.
	Local oModelZA1  := oModel:GetModel("ZA1MASTER")
	Local oModelGrid := oModel:GetModel("SA1DETAIL")
	Local cFilCli    := xFilial("SA1")
	Local cCodigo    := oModelZA1:GetValue("ZA1_CODIGO")
	Local nOperation := oModel:GetOperation()

	Begin Transaction

		If nOperation == MODEL_OPERATION_DELETE
			// Exclusao do grupo: remove o vinculo de todos os clientes antes de excluir o cabecalho
			LimpaVincGrupo(cFilCli, cCodigo)
			lRet := FWFormCommit(oModel)
		Else
			// Inclusao/Alteracao: grava o cabecalho e resincroniza os vinculos na SA1
			lRet := FWFormCommit(oModel)
			If lRet
				LimpaVincGrupo(cFilCli, cCodigo)
				lRet := GravaVincGrupo(oModelGrid, cFilCli, cCodigo)
			EndIf
		EndIf

		If !lRet
			DisarmTransaction()
		EndIf

	End Transaction

Return lRet

//-------------------------------------------------------------------------
// LimpaVincGrupo - Remove o codigo do grupo (A1_ZGRPFIN) de todos os
// clientes atualmente vinculados a ele (usado em Excluir e antes de
// resincronizar em Incluir/Alterar)
//-------------------------------------------------------------------------
Static Function LimpaVincGrupo(cFilCli, cCodigo)
	Local cAliasQry := Nil
	Local cQuery    := ""

	If Empty(cCodigo)
		Return .T.
	EndIf

	cAliasQry := GetNextAlias()

	cQuery := " SELECT A1_COD, A1_LOJA "
	cQuery += " FROM " + RetSqlName("SA1") + " SA1 "
	cQuery += " WHERE SA1.A1_FILIAL = '" + cFilCli + "' "
	cQuery += "   AND SA1.A1_ZGRPFIN = '" + cCodigo + "' "
	cQuery += "   AND SA1.D_E_L_E_T_ = ' ' "

	dbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cAliasQry, .F., .T.)

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))

	While (cAliasQry)->(!Eof())
		If SA1->(MsSeek(cFilCli + (cAliasQry)->A1_COD + (cAliasQry)->A1_LOJA))
			RecLock("SA1", .F.)
			SA1->A1_ZGRPFIN := Space(TamSX3("A1_ZGRPFIN")[1])
			SA1->(MsUnlock())
		EndIf
		(cAliasQry)->(DbSkip())
	End

	(cAliasQry)->(DbCloseArea())

Return .T.

//-------------------------------------------------------------------------
// GravaVincGrupo - Grava o codigo do grupo (A1_ZGRPFIN) em todos os
// clientes presentes na grade (linhas nao excluidas)
//-------------------------------------------------------------------------
Static Function GravaVincGrupo(oModelGrid, cFilCli, cCodigo)
	Local lRet  := .T.
	Local cCod  := ""
	Local cLoja := ""
	Local nX    := 0

	DbSelectArea("SA1")
	SA1->(DbSetOrder(1))

	For nX := 1 To oModelGrid:Length()
		oModelGrid:GoLine(nX)
		If !oModelGrid:IsDeleted()
			cCod  := oModelGrid:GetValue("A1_COD")
			cLoja := oModelGrid:GetValue("A1_LOJA")

			If SA1->(MsSeek(cFilCli + cCod + cLoja))
				RecLock("SA1", .F.)
				SA1->A1_ZGRPFIN := cCodigo
				SA1->(MsUnlock())
			EndIf
		EndIf
	Next nX

Return lRet
