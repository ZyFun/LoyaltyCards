//
//  CardsPresenter.swift
//  MobinTestTask
//
//  Created by Дмитрий Данилин on 14.04.2023.
//

import Foundation
import DTLogger

protocol CardsPresentationLogic: AnyObject {
    init(view: CardsView)
    func getServerData(offset: Int?)
}

final class CardsPresenter {
    // MARK: - Public Properties
    
    weak var view: CardsView?
    var requestService: IRequestSender?
    
    // MARK: - Private Properties
    
    private var companyAPIModel: [CompanyData] = []
    private var viewModels: [CardModel] = []
    
    // MARK: - Initializer
    
    required init(view: CardsView) {
        self.view = view
    }
    
    // MARK: - Private Methods
    
    private func parseServerDataToViewModel() {
        companyAPIModel.forEach { companyData in
            let colorsModel = CardColorsModel(
                cardBackgroundColor: companyData.mobileAppDashboard.cardBackgroundColor,
                highlightTextColor: companyData.mobileAppDashboard.highlightTextColor,
                textColor: companyData.mobileAppDashboard.textColor,
                mainColor: companyData.mobileAppDashboard.mainColor,
                accentColor: companyData.mobileAppDashboard.accentColor,
                backgroundColor: companyData.mobileAppDashboard.backgroundColor
            )
            
            let model = CardModel(
                id: companyData.company.companyId,
                name: companyData.mobileAppDashboard.companyName,
                imageUrl: companyData.mobileAppDashboard.logo,
                mark: String(companyData.customerMarkParameters.mark),
                loyaltyName: companyData.customerMarkParameters.loyaltyLevel.name,
                percent: String(companyData.customerMarkParameters.loyaltyLevel.cashToMark),
                hexColors: colorsModel
            )
            viewModels.append(model)
        }
        
        companyAPIModel = []
    }
    
    private func presentCards() {
        view?.display(models: viewModels)
        view?.dataFinishedLoaded()
    }
}

// MARK: - Presentation Logic

extension CardsPresenter: CardsPresentationLogic, CellButtonActionDelegate {
    func didPressedButton(message: String) {
        view?.showAlert(title: "", message: message, isReloadData: false)
    }
    
    func getServerData(offset: Int?) {
        view?.dataStartedLoaded()
        
        let requestConfig = RequestFactory.CompanyRequest.modelConfig(offset: offset ?? viewModels.count)
        requestService?.send(config: requestConfig) { [weak self] result in
            switch result {
            case .success(let(models, _, _)):
                models?.forEach({ model in
                    self?.companyAPIModel.append(model)
                    SystemLogger.info(model.mobileAppDashboard.companyName)
                })
                
                self?.parseServerDataToViewModel()
                DispatchQueue.main.async {
                    self?.presentCards()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.view?.showAlert(
                        title: "Ошибка",
                        message: error.describing,
                        isReloadData: true
                    )
                }
                
                SystemLogger.error(error.describing)
            }
        }
    }
}
