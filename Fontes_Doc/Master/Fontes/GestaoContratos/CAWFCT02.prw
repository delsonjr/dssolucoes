#include "totvs.ch"

/*/{Protheus.doc} CAWFCT02
Trata o retorno do e-mail de aprovacao/reprovacao de Contrato, efetiva a
decisao na alcada (MaAlcDoc) e, quando nao houver mais niveis pendentes,
dispara a notificacao final ao gestor do contrato. Nao altera o campo
CN9_SITUAC diretamente: a transicao de situacao do contrato apos a
aprovacao total e responsabilidade do motor nativo de alcada do GCT
(MV_APRMDEC/MV_ALTPDOC/MV_CNMDALC), que ja acompanha os registros da SCR.
@type function
@author Delson Junior Antunes
@since 06/07/2026
@param oProcess, object, processo de workflow retornado pelo clique no e-mail
/*/
User Function CAWFCT02(oProcess)

	Local cFilCtr  := oProcess:oHtml:RetByName('C7_FILIAL')
	Local cNumCtr  := oProcess:oHtml:RetByName('C7_NUM')
	Local nRecno   := oProcess:oHtml:RetByName('RECNO')
	Local cMotivo  := oProcess:oHtml:RetByName('MOTIVO')
	Local lAprov   := Right(AllTrim(Upper(oProcess:oHtml:RetByName('aprovacao'))), 1) == "S"
	Local lAllApv  := .T.
	Local lRejeit  := .F.
	Local aAreaSCR := SCR->(GetArea())

	dbselectarea("SCR")
	SCR->(dbGoTo(nRecno))

	If SCR->CR_STATUS <> "02"
		SCR->(RestArea(aAreaSCR))
		Return
	EndIf

	If lAprov
		MaAlcDoc({SCR->CR_NUM, SCR->CR_TIPO, SCR->CR_TOTAL, SCR->CR_APROV, , SCR->CR_GRUPO, , , , , cMotivo}, Date(), 4)
	Else
		MaAlcDoc({SCR->CR_NUM, SCR->CR_TIPO, , SCR->CR_APROV, , SCR->CR_GRUPO, , , , dDataBase, cMotivo}, Date(), 7)
		SCR->(RecLock("SCR", .F.))
		SCR->CR_OBS := AllTrim(cMotivo)
		SCR->(MsUnlock())
	EndIf

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	If SCR->(dbSeek(xFilial("SCR") + "CT" + cNumCtr))
		While !SCR->(Eof()) .And. alltrim(SCR->(CR_FILIAL + CR_TIPO + CR_NUM)) == xFilial("SCR") + "CT" + cNumCtr
			If SCR->CR_STATUS == "02"
				lAllApv := .F.
				U_CAWFCT01()
				Exit
			ElseIf SCR->CR_STATUS == "06"
				lAllApv := .F.
				lRejeit := .T.
				Exit
			EndIf
			SCR->(dbSkip())
		EndDo

		If lAllApv .Or. lRejeit
			EDNotifCT(iif(lRejeit, .F., .T.), cFilCtr, cNumCtr)
		EndIf
	EndIf

	oProcess:Finish()
	oProcess:Free()

	SCR->(RestArea(aAreaSCR))

Return

/*/{Protheus.doc} EDNotifCT
Notifica o gestor do contrato sobre o resultado final da aprovacao.
@type static function
@author Delson Junior Antunes
@since 06/07/2026
@param lStatus, logical, .T. aprovado / .F. reprovado
@param cFilCtr, character, filial do contrato
@param cNumCtr, character, numero do contrato
@return Nil
/*/
Static Function EDNotifCT(lStatus, cFilCtr, cNumCtr)

	Local oNotifica
	Local cBody    := ""
	Local aAreaCN9 := CN9->(GetArea())

	CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
	CN9->(dbSeek(cFilCtr + cNumCtr))

	oNotifica := TWFProcess():New("WFNOTIF", "E-mail de Notificacao de Contrato")
	oNotifica:NewTask("000004", "\WORKFLOW\WFNOTIFICA.HTM")

	If lStatus
		oNotifica:cSubject := "CONTRATO N. " + cNumCtr + " - APROVADO"
	Else
		oNotifica:cSubject := "CONTRATO N. " + cNumCtr + " - REJEITADO"
	EndIf

	cBody := "<b>Sr(a). " + UsrFullName(CN9->CN9_GESTC) + "</b><br><br>"

	If lStatus
		cBody += "Notificamos a aprovacao do contrato n. <b>" + cNumCtr + "</b>"
	Else
		cBody += "Notificamos a rejeicao do contrato n. <b>" + cNumCtr + "</b>"
	EndIf

	If Len(AllTrim(SCR->CR_OBS)) > 0
		cBody += "<br>Motivo: " + AllTrim(SCR->CR_OBS) + "<br><br>"
	Else
		cBody += "<br><br>"
	EndIf

	cBody += "Atenciosamente, " + "<br>"
	cBody += "Workflow Protheus | Servico de Mensagens" + "<br>"

	oNotifica:oHtml:ValByName("BODY", cBody)
	//oNotifica:cTo := UsrRetMail(CN9->CN9_GESTC)
	oNotifica:cTo := "delsonjrantunes@hotmail.com"
	oNotifica:Start()
	oNotifica:Free()

	CN9->(RestArea(aAreaCN9))

Return
