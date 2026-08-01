#Include "Protheus.ch"
#Include "Totvs.ch"
#Include "Parmtype.ch"
/*/
{Protheus.doc} CNTA300
PONTO DE ENTRADA - MVC: Manutenção de Contratos
@type function
@author Delson Junior Antunes
@since 06/07/2026
/*/

User Function CNTA300()

	Local aParam     := ParamIXB
	Local xRet       := .T.
	Local oObj       := ""
	Local cIdPonto   := ""
	Local cIdModel   := ""
	Local lIsGrid    := .F.

	If aParam <> Nil
		oObj     := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
		lIsGrid  := ( Len(aParam) > 3 )
		If cIdPonto == "MODELCOMMITNTTS"

			// --> Workflow de aprovacao por e-mail apos a confirmacao da inclusao do contrato
			If INCLUI .OR. ALTERA

				cFilCtr   := xFilial('CN9')
				cNumCtr   := CN9->CN9_NUMERO
				cRevisa   := CN9->CN9_REVISA
				lPendente := .F.
				aAreaCN9  := CN9->(GetArea())
				aAreaSCR  := SCR->(GetArea())

				If Empty(cNumCtr)
					Return
				EndIf

				SCR->(dbSetOrder(1)) // CR_FILIAL+CR_TIPO+CR_NUM+CR_NIVEL
				If SCR->(dbSeek(xFilial("SCR") + "CT" + cNumCtr))
					If SCR->CR_STATUS == "02"
						lPendente := .T.
					EndIf
				EndIf

				If lPendente
					CN9->(dbSetOrder(1)) // CN9_FILIAL+CN9_NUMERO+CN9_REVISA
					If CN9->(dbSeek(cFilCtr + cNumCtr + cRevisa))
						U_CAWFCT01()
					EndIf
				EndIf

				CN9->(RestArea(aAreaCN9))
				SCR->(RestArea(aAreaSCR))




			EndIf
		EndIf
	EndIf

Return xRet
