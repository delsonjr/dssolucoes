#include "totvs.ch"

/*/{Protheus.doc} CAWFMD02
Trata o retorno do e-mail de aprovacao/reprovacao de Medicao de Contrato,
efetiva a decisao na alcada (MaAlcDoc) e, quando nao houver mais niveis
pendentes, dispara a notificacao final ao gestor do contrato. Nao altera
nenhum campo de situacao da medicao diretamente: essa transicao e
responsabilidade do motor nativo de alcada do GCT (MV_APRMDEC/
MV_ALTPDOC/MV_CNMDALC), que ja acompanha os registros da SCR.
@type function
@author Delson Junior Antunes
@since 06/07/2026
@param oProcess, object, processo de workflow retornado pelo clique no e-mail
/*/
User Function CAWFMD02(oProcess)

	Local cFilMed  := oProcess:oHtml:RetByName('C7_FILIAL')
	Local cNumMed  := oProcess:oHtml:RetByName('C7_NUM')
	Local nRecno   := oProcess:oHtml:RetByName('RECNO')
	Local cMotivo  := oProcess:oHtml:RetByName('MOTIVO')
	Local lAprov   := Right(AllTrim(Upper(oProcess:oHtml:RetByName('aprovacao'))), 1) == "S"
	Local lAllApv  := .T.
	Local lRejeit  := .F.
	Local aAreaSCR := SCR->(GetArea())

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
	If SCR->(dbSeek(xFilial("SCR") + "MD" + cNumMed))
		While !SCR->(Eof()) .And. SCR->(CR_FILIAL + CR_TIPO + CR_NUM) == xFilial("SCR") + "MD" + cNumMed
			If SCR->CR_STATUS == "02"
				lAllApv := .F.
				U_CAWFMD01()
				Exit
			ElseIf SCR->CR_STATUS == "06"
				lAllApv := .F.
				lRejeit := .T.
				Exit
			EndIf
			SCR->(dbSkip())
		EndDo

		If lAllApv .Or. lRejeit
			EDNotifMD(!lRejeit, cFilMed, cNumMed)
		EndIf
	EndIf

	oProcess:Finish()
	oProcess:Free()

	SCR->(RestArea(aAreaSCR))

Return

/*/{Protheus.doc} EDNotifMD
Notifica o gestor do contrato sobre o resultado final da aprovacao da
medicao.
@type static function
@author Equipe DSSolucoes
@since 06/07/2026
@param lStatus, logical, .T. aprovado / .F. reprovado
@param cFilMed, character, filial da medicao
@param cNumMed, character, numero da medicao
@return Nil
/*/
Static Function EDNotifMD(lStatus, cFilMed, cNumMed)

	Local oNotifica
	Local cBody    := ""
	Local aAreaCND := CND->(GetArea())
	Local aAreaCN9 := CN9->(GetArea())

	CND->(dbSetOrder(1)) // CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMMED
	CND->(dbSeek(cFilMed + cNumMed))

	CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
	CN9->(dbSeek(CND->CND_FILIAL + CND->CND_CONTRA + CND->CND_REVISA))

	oNotifica := TWFProcess():New("WFNOTIF", "E-mail de Notificacao de Medicao de Contrato")
	oNotifica:NewTask("000004", "\WORKFLOW\modelos_workflow\WFNOTIFICA.HTM")

	If lStatus
		oNotifica:cSubject := "MEDICAO DE CONTRATO N. " + cNumMed + " - APROVADA"
	Else
		oNotifica:cSubject := "MEDICAO DE CONTRATO N. " + cNumMed + " - REJEITADA"
	EndIf

	cBody := "<b>Sr(a). " + UsrFullName(CN9->CN9_GESTC) + "</b><br><br>"

	If lStatus
		cBody += "Notificamos a aprovacao da medicao de contrato n. <b>" + cNumMed + "</b>"
	Else
		cBody += "Notificamos a rejeicao da medicao de contrato n. <b>" + cNumMed + "</b>"
	EndIf

	If Len(AllTrim(SCR->CR_OBS)) > 0
		cBody += "<br>Motivo: " + AllTrim(SCR->CR_OBS) + "<br><br>"
	Else
		cBody += "<br><br>"
	EndIf

	cBody += "Atenciosamente, " + "<br>"
	cBody += "Workflow Protheus | Servico de Mensagens" + "<br>"

	oNotifica:oHtml:ValByName("BODY", cBody)
	oNotifica:cTo := UsrRetMail(CN9->CN9_GESTC)

	oNotifica:Start()
	oNotifica:Free()

	CN9->(RestArea(aAreaCN9))
	CND->(RestArea(aAreaCND))

Return
