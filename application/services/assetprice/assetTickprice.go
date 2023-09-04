package assetprice

import (
	"fmt"
	"strings"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/database/barprice"
	"github.com/FortesenseLabs/wisefinance-mtservices/application/database/tickprice"
	tickPriceModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/assetprice"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/patrickmn/go-cache"
)

// Service is a struct that contains the repository implementation for asset price service
type Service struct {
	Name                string
	BarPriceRepository  barprice.Repository
	TickPriceRepository tickprice.Repository
	Logger              *logger.Logger // logger
	Cache               *cache.Cache
}

// GetAllTicks is a function that returns tick history
func (s *Service) GetAllTicks() (*[]tickPriceModel.TickData, error) {
	return s.TickPriceRepository.GetAll()
}

// GetTickByID is a function that returns a tick by id
func (s *Service) GetTickByID(id string) (*tickPriceModel.TickData, error) {
	return s.TickPriceRepository.GetByID(id)
}

// GetOneByMap is a function that returns a tick by map
func (s *Service) GetOneTickByMap(tickMap map[string]interface{}) (*tickPriceModel.TickData, error) {
	return s.TickPriceRepository.GetOneByMap(tickMap)
}

// Delete is a function that deletes a tick by id
func (s *Service) DeleteTick(id string) error {
	return s.TickPriceRepository.Delete(id)
}

// Update is a function that updates a tick by id
func (s *Service) UpdateTick(tickId string, tickMap map[string]interface{}) (*tickPriceModel.TickData, error) {
	return s.TickPriceRepository.Update(tickId, tickMap)
}

// CreateTick is a function that creates a new tick
func (s *Service) CreateTick(tick *tickPriceModel.TickData) (*tickPriceModel.TickData, error) {
	// time(timestamp) => time(timestamp) * 1e12
	// for data.tick [time(timestamp), bid, ask]

	tick, err := s.TickPriceRepository.Create(tick)
	if err != nil {
		errMsg := "failed to create tick"
		s.Logger.Error(fmt.Errorf("%s for %s: %v", errMsg, tick.Time, err))
		splittedString := strings.Split(err.Error(), ":")
		formattedErrMsg := strings.TrimSpace(splittedString[len(splittedString)-1])
		return nil, fmt.Errorf("%s: %s", errMsg, formattedErrMsg)
	}

	return tick, nil
}
