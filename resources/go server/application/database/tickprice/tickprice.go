// Package tickprice contains the business logic for the tickprice entity
package tickprice

import (
	"encoding/json"

	tickPriceModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/assetprice"
	errorsModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/errors"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository is a struct that contains the database implementation for tick price entity
type Repository struct {
	Name   string
	DB     *gorm.DB
	Logger *logger.Logger
}

// GetAll Fetch all tick data
func (r *Repository) GetAll() (*[]tickPriceModel.TickData, error) {
	var ticks []TickData
	err := r.DB.Find(&ticks).Error
	if err != nil {
		r.Logger.Error(err)

		err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		return nil, err
	}

	return arrayToDomainMapper(&ticks), err
}

// Create ... Insert New data
func (r *Repository) Create(tickPrice *tickPriceModel.TickData) (*tickPriceModel.TickData, error) {
	tickPrice.ID = uuid.New().String()
	tickRepository := fromDomainMapper(tickPrice)
	txDb := r.DB.Create(tickRepository)
	err := txDb.Error
	if err != nil {
		r.Logger.Error(err)

		byteErr, _ := json.Marshal(err)
		var newError errorsModel.GormErr
		err = json.Unmarshal(byteErr, &newError)
		if err != nil {
			return &tickPriceModel.TickData{}, err
		}
		switch newError.Number {
		case 1062:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.ResourceAlreadyExists)
			return &tickPriceModel.TickData{}, err

		default:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		}
	}
	return tickRepository.toDomainMapper(), err
}

// GetOneByMap ... Fetch only one one tick by Map values
func (r *Repository) GetOneByMap(tickMap map[string]interface{}) (*tickPriceModel.TickData, error) {
	var tickRepository TickData

	tx := r.DB.Where(tickMap).Limit(1).Find(&tickRepository)
	if tx.Error != nil {
		r.Logger.Error(tx.Error)

		err := errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		return &tickPriceModel.TickData{}, err
	}
	return tickRepository.toDomainMapper(), nil
}

// GetByID ... Fetch only one tick by ID
func (r *Repository) GetByID(id string) (*tickPriceModel.TickData, error) {
	var tick TickData
	err := r.DB.Where("id = ?", id).First(&tick).Error

	if err != nil {
		r.Logger.Error(err)

		switch err.Error() {
		case gorm.ErrRecordNotFound.Error():
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.NotFound)
		default:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		}
	}

	return tick.toDomainMapper(), err
}

// Update ... Update tick
func (r *Repository) Update(id string, tickMap map[string]interface{}) (*tickPriceModel.TickData, error) {
	var tick TickData

	tick.ID = id
	err := r.DB.Model(&tick).
		Updates(tickMap).Error
	// Select("tick", "balance", "accountNumber", "trackingReference").

	// err = config.DB.Save(tick).Error
	if err != nil {
		r.Logger.Error(err)

		byteErr, _ := json.Marshal(err)
		var newError errorsModel.GormErr
		err = json.Unmarshal(byteErr, &newError)
		if err != nil {
			return &tickPriceModel.TickData{}, err
		}
		switch newError.Number {
		case 1062:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.ResourceAlreadyExists)
		default:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		}
		return &tickPriceModel.TickData{}, err

	}

	err = r.DB.Where("id = ?", id).First(&tick).Error

	return tick.toDomainMapper(), err
}

// Delete ... Delete tick
func (r *Repository) Delete(id string) (err error) {
	tx := r.DB.Delete(&TickData{}, id)
	if tx.Error != nil {
		r.Logger.Error(tx.Error)

		err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		return
	}

	if tx.RowsAffected == 0 {
		err = errorsModel.NewAppErrorWithType(nil, errorsModel.NotFound)
	}

	return
}
