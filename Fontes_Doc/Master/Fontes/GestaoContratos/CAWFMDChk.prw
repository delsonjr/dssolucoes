#include "totvs.ch"

/*/{Protheus.doc} CAWFMDChk
Verifica se a inclusao da medicao gerou pendencia de alcada (SCR,
CR_TIPO = "MD") e, em caso positivo, posiciona CND e dispara o e-mail de
aprovacao (CAWFMD01). Chamada pelo ponto de entrada CNTA121, no evento
MODELCOMMITNTTS.
@type function
@author Delson Junior Antunes
@since 06/07/2026
@param oModel, object, modelo de dados da medicao (CNTA121) recebido em ParamIXB[1]
/*/
User Function CAWFMDChk(oModel)

	Local cFilMed   := oModel:GetValue("CND_FILIAL")
	Local cContrato := oModel:GetValue("CND_CONTRA")
	Local cRevisa   := oModel:GetValue("CND_REVISA")
	Local cNumMed   := oModel:GetValue("CND_NUMMED")
	Local lPendente := .F.
	Local aAreaCND  := CND->(GetArea())
	Local aAreaSCR  := SCR->(GetArea())

	If Empty(cNumMed)
		Return
	EndIf

	SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
	If SCR->(dbSeek(xFilial("SCR") + "MD" + cNumMed))
		If SCR->CR_STATUS == "02"
			lPendente := .T.
		EndIf
	EndIf

	If lPendente
		CND->(dbSetOrder(1)) // CND_FILIAL+CND_CONTRA+CND_REVISA+CND_NUMMED
		If CND->(dbSeek(cFilMed + cContrato + cRevisa + cNumMed))
			U_CAWFMD01()
		EndIf
	EndIf

	CND->(RestArea(aAreaCND))
	SCR->(RestArea(aAreaSCR))

Return
