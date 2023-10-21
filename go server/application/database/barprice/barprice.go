// Package barprice contains the business logic for the barprice entity
package barprice

import (
	"encoding/json"

	barPriceModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/assetprice"
	errorsModel "github.com/FortesenseLabs/wisefinance-mtservices/application/models/errors"

	"github.com/FortesenseLabs/wisefinance-mtservices/application/utils/logger"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// Repository is a struct that contains the database implementation for bar price entity
type Repository struct {
	Name   string
	DB     *gorm.DB
	Logger *logger.Logger
}

// GetAll Fetch all bar data
func (r *Repository) GetAll() (*[]barPriceModel.BarData, error) {
	var bars []BarData
	err := r.DB.Find(&bars).Error
	if err != nil {
		r.Logger.Error(err)

		err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		return nil, err
	}

	return arrayToDomainMapper(&bars), err
}

// Create ... Insert New data
func (r *Repository) Create(barPrice *barPriceModel.BarData) (*barPriceModel.BarData, error) {
	barPrice.ID = uuid.New().String()
	barRepository := fromDomainMapper(barPrice)
	txDb := r.DB.Create(barRepository)
	err := txDb.Error
	if err != nil {
		r.Logger.Error(err)

		byteErr, _ := json.Marshal(err)
		var newError errorsModel.GormErr
		err = json.Unmarshal(byteErr, &newError)
		if err != nil {
			return &barPriceModel.BarData{}, err
		}
		switch newError.Number {
		case 1062:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.ResourceAlreadyExists)
			return &barPriceModel.BarData{}, err

		default:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		}
	}
	return barRepository.toDomainMapper(), err
}

// GetOneByMap ... Fetch only one one bar by Map values
func (r *Repository) GetOneByMap(barMap map[string]interface{}) (*barPriceModel.BarData, error) {
	var barRepository BarData

	tx := r.DB.Where(barMap).Limit(1).Find(&barRepository)
	if tx.Error != nil {
		r.Logger.Error(tx.Error)

		err := errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		return &barPriceModel.BarData{}, err
	}
	return barRepository.toDomainMapper(), nil
}

// GetByID ... Fetch only one bar by ID
func (r *Repository) GetByID(id string) (*barPriceModel.BarData, error) {
	var bar BarData
	err := r.DB.Where("id = ?", id).First(&bar).Error

	if err != nil {
		r.Logger.Error(err)

		switch err.Error() {
		case gorm.ErrRecordNotFound.Error():
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.NotFound)
		default:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		}
	}

	return bar.toDomainMapper(), err
}

// Update ... Update bar
func (r *Repository) Update(id string, barMap map[string]interface{}) (*barPriceModel.BarData, error) {
	var bar BarData

	bar.ID = id
	err := r.DB.Model(&bar).
		Updates(barMap).Error
	// Select("bar", "balance", "accountNumber", "trackingReference").

	// err = config.DB.Save(bar).Error
	if err != nil {
		r.Logger.Error(err)

		byteErr, _ := json.Marshal(err)
		var newError errorsModel.GormErr
		err = json.Unmarshal(byteErr, &newError)
		if err != nil {
			return &barPriceModel.BarData{}, err
		}
		switch newError.Number {
		case 1062:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.ResourceAlreadyExists)
		default:
			err = errorsModel.NewAppErrorWithType(nil, errorsModel.UnknownError)
		}
		return &barPriceModel.BarData{}, err

	}

	err = r.DB.Where("id = ?", id).First(&bar).Error

	return bar.toDomainMapper(), err
}

// Delete ... Delete bar
func (r *Repository) Delete(id string) (err error) {
	tx := r.DB.Delete(&BarData{}, id)
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
